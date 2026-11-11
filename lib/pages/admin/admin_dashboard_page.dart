
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - ADMIN DASHBOARD
// ============================================================
//
// Admin-oikeus tarkistetaan Firebase Custom Claimista.
// Varsinaiset tiedot haetaan palvelimelta.
// Firestorea ei lueta suoraan Flutter-sovelluksesta.
//
// ============================================================

class AdminDashboardPage extends StatefulWidget {
  final String languageCode;

  const AdminDashboardPage({
    super.key,
    this.languageCode = 'fi',
  });

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  // ==========================================================
  // 🎨 STELLA THEME
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color surfaceColor =
      Color(0xFF1A0E31);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color purpleColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color primaryTextColor =
      Color(0xFFF8F4FF);

  static const Color secondaryTextColor =
      Color(0xFFBDB4D1);

  static const Color greenColor =
      Color(0xFF65D6A0);

  static const Color redColor =
      Color(0xFFFF6B7A);

  // ==========================================================
  // 🔥 FIREBASE
  // ==========================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ==========================================================
  // 📊 STATE
  // ==========================================================

  bool _loading = true;
  bool _authorized = false;

  String? _errorMessage;

  int _totalUsers = 0;
  int _activeMiners = 0;
  int _premiumPlusUsers = 0;
  int _endingSoon = 0;

  DateTime? _generatedAt;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _activeMinerList = [];

  // ==========================================================
  // 🌐 LANGUAGE
  // ==========================================================

  bool get _isFinnish =>
      widget.languageCode
          .toLowerCase()
          .startsWith('fi');

  String _text(
    String fi,
    String en,
  ) {
    return _isFinnish ? fi : en;
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ==========================================================
  // 🔐 ADMIN AUTHORIZATION
  // ==========================================================

  Future<bool> _checkAdminAccess() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // Pakotetaan uuden ID-tokenin haku.
    // Näin juuri myönnetty admin-claim päivittyy.
    final IdTokenResult tokenResult =
        await user.getIdTokenResult(true);

    return tokenResult.claims?['admin'] == true;
  }

  // ==========================================================
  // 📡 LOAD DASHBOARD
  // ==========================================================

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final bool isAdmin =
          await _checkAdminAccess();

      if (!mounted) return;

      if (!isAdmin) {
        setState(() {
          _authorized = false;
          _loading = false;
          _errorMessage = _text(
            'Sinulla ei ole ylläpitäjän oikeuksia.',
            'You do not have administrator access.',
          );
        });

        return;
      }

      _authorized = true;

      final HttpsCallable callable =
          _functions.httpsCallable(
        'getAdminDashboard',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final HttpsCallableResult<dynamic> result =
          await callable.call(
        <String, dynamic>{
          'pageSize': 50,
        },
      );

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (data['success'] != true) {
        throw Exception(
          'Dashboard request failed.',
        );
      }

      final List<Map<String, dynamic>> users =
          _parseList(data['users']);

      final List<Map<String, dynamic>> activeMiners =
          _parseList(data['activeMinerList']);

      if (!mounted) return;

      setState(() {
        _totalUsers =
            _toInt(data['totalUsers']);

        _activeMiners =
            _toInt(data['activeMiners']);

        _premiumPlusUsers =
            _toInt(data['premiumPlusUsers']);

        _endingSoon =
            _toInt(data['endingSoon']);

        _users = users;
        _activeMinerList = activeMiners;

        _generatedAt = _parseDate(
          data['generatedAt'],
        );

        _loading = false;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        if (error.code == 'permission-denied') {
          _authorized = false;
          _errorMessage = _text(
            'Palvelin hylkäsi ylläpitäjän oikeuden.',
            'The server denied administrator access.',
          );
        } else if (error.code == 'unauthenticated') {
          _errorMessage = _text(
            'Kirjaudu uudelleen sisään.',
            'Please sign in again.',
          );
        } else {
          _errorMessage =
              error.message ??
              _text(
                'Hallintatietojen hakeminen epäonnistui.',
                'Failed to load dashboard data.',
              );
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _text(
          'Hallintatietojen hakeminen epäonnistui.',
          'Failed to load dashboard data.',
        );
      });
    }
  }

  // ==========================================================
  // DATA HELPERS
  // ==========================================================

  List<Map<String, dynamic>> _parseList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _formatDate(dynamic value) {
    final DateTime? date = _parseDate(value);

    if (date == null) {
      return '—';
    }

    final DateTime local = date.toLocal();

    final String day =
        local.day.toString().padLeft(2, '0');

    final String month =
        local.month.toString().padLeft(2, '0');

    final String hour =
        local.hour.toString().padLeft(2, '0');

    final String minute =
        local.minute.toString().padLeft(2, '0');

    return '$day.$month.${local.year} $hour:$minute';
  }

  String _formatNumber(dynamic value) {
    final double number = _toDouble(value);

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  String _tierName(dynamic value) {
    switch (value?.toString()) {
      case 'premium_plus':
        return 'Premium Plus';

      case 'premium':
        return 'Premium';

      default:
        return 'Free';
    }
  }

  // ==========================================================
  // 📊 SUMMARY CARD
  // ==========================================================

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📊 SUMMARY
  // ==========================================================

  Widget _buildSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 11,
      mainAxisSpacing: 11,
      childAspectRatio: 1.48,
      children: [
        _buildSummaryCard(
          title: _text(
            'Kaikki käyttäjät',
            'Total users',
          ),
          value: _totalUsers,
          icon: Icons.people_alt_rounded,
          color: purpleColor,
        ),
        _buildSummaryCard(
          title: _text(
            'Aktiiviset louhijat',
            'Active miners',
          ),
          value: _activeMiners,
          icon: Icons.bolt_rounded,
          color: greenColor,
        ),
        _buildSummaryCard(
          title: 'Premium Plus',
          value: _premiumPlusUsers,
          icon: Icons.workspace_premium_rounded,
          color: goldColor,
        ),
        _buildSummaryCard(
          title: _text(
            'Päättyy tunnin sisällä',
            'Ending within one hour',
          ),
          value: _endingSoon,
          icon: Icons.timer_rounded,
          color: pinkColor,
        ),
      ],
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 23,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: purpleColor,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 👤 USER CARD
  // ==========================================================

  Widget _buildUserCard(
    Map<String, dynamic> user, {
    required bool showMiningStatus,
  }) {
    final bool miningActive =
        user['miningActive'] == true;

    final bool endingSoon =
        user['endingSoon'] == true;

    final String username =
        user['username']?.toString() ?? '—';

    final String tier =
        _tierName(user['premiumTier']);

    final double hashRate =
        _toDouble(user['hashRate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: endingSoon
              ? pinkColor.withValues(alpha: 0.6)
              : purpleColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    purpleColor.withValues(alpha: 0.18),
                child: const Icon(
                  Icons.person_rounded,
                  color: purpleColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tier,
                      style: const TextStyle(
                        color: goldColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showMiningStatus)
                _buildStatusBadge(
                  miningActive: miningActive,
                  endingSoon: endingSoon,
                ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 15,
            runSpacing: 8,
            children: [
              _buildInfo(
                Icons.speed_rounded,
                '${_formatNumber(hashRate)} H/s',
              ),
              _buildInfo(
                Icons.account_balance_wallet_rounded,
                '${_formatNumber(user['miningBalance'])} STL',
              ),
            ],
          ),
          if (showMiningStatus) ...[
            const SizedBox(height: 11),
            _buildInfo(
              Icons.flag_rounded,
              '${_text('Päättyy', 'Ends')}: '
              '${_formatDate(user['miningEndsAt'])}',
            ),
          ],
          if (user['premiumExpiryTime'] != null) ...[
            const SizedBox(height: 8),
            _buildInfo(
              Icons.workspace_premium_rounded,
              '${_text('Tilaus päättyy', 'Subscription ends')}: '
              '${_formatDate(user['premiumExpiryTime'])}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool miningActive,
    required bool endingSoon,
  }) {
    final Color color = endingSoon
        ? pinkColor
        : miningActive
            ? greenColor
            : secondaryTextColor;

    final String label = endingSoon
        ? _text('Päättyy pian', 'Ending soon')
        : miningActive
            ? _text('Louhii', 'Mining')
            : _text('Ei louhi', 'Inactive');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: secondaryTextColor,
          size: 15,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // 🚫 ERROR VIEW
  // ==========================================================

  Widget _buildError() {
    final bool denied = !_authorized;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              denied
                  ? Icons.lock_rounded
                  : Icons.error_outline_rounded,
              color: denied ? goldColor : redColor,
              size: 48,
            ),
            const SizedBox(height: 15),
            Text(
              _errorMessage ??
                  _text(
                    'Tietojen hakeminen epäonnistui.',
                    'Could not load data.',
                  ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _text('Yritä uudelleen', 'Try again'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleColor,
                foregroundColor: backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        title: Text(
          _text(
            'Stelluriini Hallinta',
            'Stelluriini Admin',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _text('Päivitä', 'Refresh'),
            onPressed: _loading
                ? null
                : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
              color: purpleColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: purpleColor,
                ),
              )
            : _errorMessage != null
                ? _buildError()
                : RefreshIndicator(
                    color: purpleColor,
                    backgroundColor: cardColor,
                    onRefresh: _loadDashboard,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        30,
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius:
                                BorderRadius.circular(17),
                            border: Border.all(
                              color: goldColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                color: goldColor,
                                size: 27,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _text(
                                        'Ylläpitäjän näkymä',
                                        'Administrator dashboard',
                                      ),
                                      style: const TextStyle(
                                        color: primaryTextColor,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _text(
                                        'Palvelimelta haetut tiedot',
                                        'Data retrieved from server',
                                      ),
                                      style: const TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildSummary(),
                        _buildSectionTitle(
                          _text(
                            'Aktiiviset louhijat',
                            'Active miners',
                          ),
                          Icons.bolt_rounded,
                        ),
                        if (_activeMinerList.isEmpty)
                          _buildEmptyMessage(
                            _text(
                              'Aktiivisia louhijoita ei löytynyt.',
                              'No active miners found.',
                            ),
                          )
                        else
                          ..._activeMinerList.map(
                            (user) => _buildUserCard(
                              user,
                              showMiningStatus: true,
                            ),
                          ),
                        _buildSectionTitle(
                          _text(
                            'Käyttäjät',
                            'Users',
                          ),
                          Icons.people_alt_rounded,
                        ),
                        if (_users.isEmpty)
                          _buildEmptyMessage(
                            _text(
                              'Käyttäjiä ei löytynyt.',
                              'No users found.',
                            ),
                          )
                        else
                          ..._users.map(
                            (user) => _buildUserCard(
                              user,
                              showMiningStatus: true,
                            ),
                          ),
                        if (_generatedAt != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 12),
                            child: Text(
                              '${_text('Päivitetty', 'Updated')}: '
                              '${_formatDate(_generatedAt!.toIso8601String())}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 13,
        ),
      ),
    );
  }
}
