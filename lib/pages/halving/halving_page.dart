
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - HALVING & MINING RATE
// ============================================================
//
// Shows server-reported halving multiplier and mining rates.
// Registered user count is not guessed because the current
// getMiningStatus response does not expose that value.
//
// ============================================================

class HalvingPage extends StatefulWidget {
  final String languageCode;

  const HalvingPage({
    super.key,
    this.languageCode = 'en',
  });

  @override
  State<HalvingPage> createState() => _HalvingPageState();
}

class _HalvingPageState extends State<HalvingPage> {
  // Stella theme
  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color purpleColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);
  static const Color errorColor = Color(0xFFFF6B7A);
  static const Color successColor = Color(0xFF75E0A3);

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Must match functions/src/config/miningConfig.js.
  static const List<_HalvingMilestone> _milestones = [
    _HalvingMilestone(users: 0, multiplier: 1.0),
    _HalvingMilestone(users: 100, multiplier: 0.5),
    _HalvingMilestone(users: 1000, multiplier: 0.25),
    _HalvingMilestone(users: 10000, multiplier: 0.125),
    _HalvingMilestone(users: 100000, multiplier: 0.0625),
    _HalvingMilestone(users: 1000000, multiplier: 0.03125),
    _HalvingMilestone(users: 10000000, multiplier: 0.015625),
    _HalvingMilestone(users: 100000000, multiplier: 0.0078125),
  ];

  bool _loading = true;
  bool _miningActive = false;
  bool _adBoostActive = false;

  String? _error;

  double _multiplier = 1.0;
  double _hashRate = 0.0;
  double _miningPerHour = 0.0;
  double _activeMiningPerHour = 0.0;

  bool get _isFinnish =>
      widget.languageCode.toLowerCase().startsWith('fi');

  String _text(String fi, String en) => _isFinnish ? fi : en;

  // Use the server's effective rate when Power Boost is active.
  double get _displayMiningPerHour =>
      _adBoostActive ? _activeMiningPerHour : _miningPerHour;

  @override
  void initState() {
    super.initState();
    _loadHalvingStatus();
  }

  // ==========================================================
  // LOAD CURRENT SERVER STATUS
  // ==========================================================

  Future<void> _loadHalvingStatus() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final callable = _functions.httpsCallable('getMiningStatus');
      final result = await callable.call();
      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception('Invalid mining status response.');
      }

      final data = Map<String, dynamic>.from(raw);

      final multiplier =
          _readDouble(data['miningHalvingMultiplier']) ?? 1.0;

      final hashRate =
          _readDouble(data['hashRate']) ?? 0.0;

      final miningPerHour =
          _readDouble(data['miningPerHour']) ?? 0.0;

      final activeMiningPerHour =
          _readDouble(data['activeMiningPerHour']) ?? miningPerHour;

      final miningActive =
          data['miningActive'] == true;

      final adBoostActive =
          data['adBoostActive'] == true;

      if (!multiplier.isFinite ||
          multiplier <= 0 ||
          multiplier > 1) {
        throw Exception('Invalid halving multiplier.');
      }

      if (!mounted) return;

      setState(() {
        _multiplier = multiplier;

        _hashRate =
            hashRate.isFinite && hashRate > 0 ? hashRate : 0.0;

        _miningPerHour =
            miningPerHour.isFinite && miningPerHour >= 0
                ? miningPerHour
                : 0.0;

        _activeMiningPerHour =
            activeMiningPerHour.isFinite &&
                    activeMiningPerHour >= 0
                ? activeMiningPerHour
                : _miningPerHour;

        _miningActive = miningActive;
        _adBoostActive = adBoostActive;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int get _currentLevel {
    for (int i = 0; i < _milestones.length; i++) {
      if ((_milestones[i].multiplier - _multiplier).abs() <
          0.000000001) {
        return i;
      }
    }
    return 0;
  }

  String _formatMultiplier(double value) {
    return '${value.toStringAsFixed(7).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}×';
  }

  String _formatNumber(int value) {
    final source = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(source[i]);
    }

    return result.toString();
  }

  // ==========================================================
  // PAGE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        title: Text(
          _text('Halving ja louhintakerroin', 'Halving & Mining Rate'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _text('Päivitä', 'Refresh'),
            onPressed: _loading ? null : _loadHalvingStatus,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: purpleColor,
        backgroundColor: cardColor,
        onRefresh: _loadHalvingStatus,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 16),
            if (_loading)
              _buildLoadingCard()
            else if (_error != null)
              _buildErrorCard()
            else
              _buildCurrentStatusCard(),
            const SizedBox(height: 18),
            _buildChartCard(),
            const SizedBox(height: 18),
            _buildFormulaCard(),
            const SizedBox(height: 18),
            _buildCycleInformationCard(),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INTRO
  // ==========================================================

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            purpleColor.withValues(alpha: 0.20),
            pinkColor.withValues(alpha: 0.08),
            cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: purpleColor.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: goldColor,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                'STELLURIINI • STL',
                style: TextStyle(
                  color: pinkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _text(
              'Yhteisön kasvaessa louhintakerroin pienenee.',
              'As the community grows, the mining multiplier decreases.',
            ),
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 21,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _text(
              'Halving-portaat perustuvat kaikkien rekisteröityneiden käyttäjien määrään.',
              'Halving milestones are based on the total number of registered users.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CURRENT SERVER STATUS
  // ==========================================================

  Widget _buildCurrentStatusCard() {
    final level = _currentLevel;
    final levelColor = level == 0 ? goldColor : purpleColor;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                color: goldColor,
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text(
                    'Palvelimen ilmoittama kerroin',
                    'Multiplier reported by server',
                  ),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                _miningActive
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: _miningActive
                    ? successColor
                    : secondaryTextColor,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _formatMultiplier(_multiplier),
              style: TextStyle(
                color: levelColor,
                fontSize: 43,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              _text(
                'Halving-taso ${level + 1} / ${_milestones.length}',
                'Halving level ${level + 1} / ${_milestones.length}',
              ),
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: purpleColor.withValues(alpha: 0.18)),
          const SizedBox(height: 9),
          _infoRow(
            _text('Louhinnan tila', 'Mining status'),
            _miningActive
                ? _text('Aktiivinen', 'Active')
                : _text('Ei aktiivista jaksoa', 'No active cycle'),
          ),
          const SizedBox(height: 9),
          _infoRow(
            'Hash Rate',
            _hashRate.toStringAsFixed(4),
          ),
          const SizedBox(height: 9),
          _infoRow(
            _text('Power Boost', 'Power Boost'),
            _adBoostActive
                ? _text('Aktiivinen', 'Active')
                : _text('Ei aktiivinen', 'Inactive'),
            valueColor: _adBoostActive
                ? successColor
                : secondaryTextColor,
          ),
          const SizedBox(height: 9),
          _infoRow(
            _text('Normaali louhinta / tunti', 'Normal mining / hour'),
            '${_miningPerHour.toStringAsFixed(6)} STL',
          ),
          const SizedBox(height: 9),
          _infoRow(
            _text(
              'Todellinen nopeus / tunti',
              'Effective mining / hour',
            ),
            '${_displayMiningPerHour.toStringAsFixed(6)} STL',
            valueColor: goldColor,
          ),
          const SizedBox(height: 12),
          Text(
            _miningActive
                ? _text(
                    'Kerroin ja louhintanopeudet on haettu palvelimelta. Power Boostin vaikutus näkyy todellisessa tuntinopeudessa.',
                    'The multiplier and mining rates are loaded from the server. Power Boost is reflected in the effective hourly rate.',
                  )
                : _text(
                    'Kerroin on käyttäjäprofiilista palvelimelta palautettu arvo. Uusi kerroin määräytyy seuraavan louhintajakson alkaessa.',
                    'This is the value returned from your profile. A new multiplier is assigned when the next mining cycle starts.',
                  ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HALVING CHART
  // ==========================================================

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: pinkColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Halving-kaavio', 'Halving chart'),
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _text(
              'Louhintakerroin puolittuu jokaisella uudella rajalla.',
              'The mining multiplier is halved at every new milestone.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          ...List.generate(_milestones.length, (index) {
            final item = _milestones[index];

            final selected =
                (item.multiplier - _multiplier).abs() < 0.000000001;

            final progress =
                (item.multiplier / _milestones.first.multiplier)
                    .clamp(0.0, 1.0);

            final color = selected
                ? goldColor
                : index.isEven
                    ? purpleColor
                    : pinkColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _text(
                                  '${_formatNumber(item.users)} käyttäjää',
                                  '${_formatNumber(item.users)} users',
                                ),
                                style: const TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatMultiplier(item.multiplier),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: surfaceColor,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _text(
                          'Palvelimen palauttama kerroin',
                          'Multiplier returned by server',
                        ),
                        style: const TextStyle(
                          color: goldColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          Text(
            _text(
              'Palkit kuvaavat kunkin tason kerrointa suhteessa alkuperäiseen 1,0× tasoon.',
              'Bars show each multiplier relative to the initial 1.0× level.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MINING FORMULA
  // ==========================================================

  Widget _buildFormulaCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: goldColor),
              SizedBox(width: 9),
              Text(
                'MINING FORMULA',
                style: TextStyle(
                  color: goldColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Hash Rate × 0.10 × Halving Multiplier',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _text(
              'Esimerkki: 1 HR × 0,10 × 0,5 = 0,05 STL tunnissa.',
              'Example: 1 HR × 0.10 × 0.5 = 0.05 STL per hour.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MINING CYCLE INFORMATION
  // ==========================================================

  Widget _buildCycleInformationCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: purpleColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                color: pinkColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text(
                    'Milloin halving vaikuttaa?',
                    'When does halving take effect?',
                  ),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Louhintajakson kerroin tallennetaan jakson alkaessa. Jos käyttäjämäärä ylittää uuden halving-rajan kesken jakson, käynnissä oleva jakso jatkaa omalla tallennetulla kertoimellaan. Uusi kerroin otetaan käyttöön seuraavan louhintajakson alkaessa.',
              'The multiplier is stored when a mining cycle starts. If the registered user count crosses a new halving milestone during a cycle, that cycle continues with its stored multiplier. The new multiplier is applied when the next mining cycle starts.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOADING AND ERROR
  // ==========================================================

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: purpleColor),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: errorColor,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            _text(
              'Halving-tietoja ei voitu hakea.',
              'Could not load halving information.',
            ),
            style: const TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _text(
              'Tarkista verkkoyhteys ja yritä uudelleen.',
              'Check your connection and try again.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadHalvingStatus,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Yritä uudelleen', 'Try again')),
              style: TextButton.styleFrom(
                foregroundColor: purpleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  Widget _infoRow(
    String label,
    String value, {
    Color valueColor = primaryTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Icon(
          Icons.pets_rounded,
          color: pinkColor,
          size: 25,
        ),
        const SizedBox(height: 8),
        Text(
          _text(
            'Stella seuraa Stelluriinin kasvua 🐾',
            'Stella is watching Stelluriini grow 🐾',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: pinkColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'STELLURIINI • STL • SOLANA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HALVING MILESTONE MODEL
// ============================================================

class _HalvingMilestone {
  final int users;
  final double multiplier;

  const _HalvingMilestone({
    required this.users,
    required this.multiplier,
  });
}
