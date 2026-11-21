import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// 🐱 STELLURIINI - GUILD PAGE
// ============================================================
// Guild community UI backed by the existing Firebase callable functions.
// Callable functions used:
//   getGuildData()
//   createGuild({name})
//   joinGuild({inviteCode})
// ============================================================

class GuildPage extends StatefulWidget {
  final String languageCode;


  const GuildPage({
    super.key,
    required this.languageCode,
  });



  @override
  State<GuildPage> createState() => _GuildPageState();
}



class _GuildPageState extends State<GuildPage> {
  static const Color _background = Color(0xFF120B24);
  static const Color _surface = Color(0xFF1A0E31);
  static const Color _card = Color(0xFF21113B);
  static const Color _purple = Color(0xFFB58CFF);
  static const Color _pink = Color(0xFFFFB7E8);
  static const Color _gold = Color(0xFFFFD166);
  static const Color _text = Color(0xFFF8F4FF);
  static const Color _muted = Color(0xFFBDB4D1);
  static const Color _green = Color(0xFF71E0B5);
  static const Color _red = Color(0xFFFF7B91);

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');


  final TextEditingController _guildNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();


  Map<String, dynamic>? _guildData;
  bool _loading = true;
  bool _creating = false;
  bool _joining = false;
  String? _error;
  String? _notice;


  bool get _isFinnish => widget.languageCode.toLowerCase().startsWith('fi');


  String _t(String fi, String en) => _isFinnish ? fi : en;


  @override
  void initState() {
    super.initState();
    _loadGuildData();
  }


  @override
  void dispose() {
    _guildNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }


  Future<void> _loadGuildData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _functions.httpsCallable('getGuildData').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      setState(() {
        _guildData = data;
        _loading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? _t('Guild-tietojen lataus epäonnistui.', 'Could not load Guild data.');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _t('Guild-tietojen lataus epäonnistui.', 'Could not load Guild data.');
        _loading = false;
      });
    }
  }


  Future<void> _createGuild() async {
    final name = _guildNameController.text.trim();
    if (name.length < 3 || name.length > 24) {
      _showMessage(_t('Guild-nimen tulee olla 3–24 merkkiä.', 'Guild name must be 3–24 characters.'));
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await _functions.httpsCallable('createGuild').call({'name': name});
      final data = Map<String, dynamic>.from(result.data as Map);
      _guildNameController.clear();
      if (mounted) {
        setState(() {
          _notice = data['message']?.toString() ?? _t('Guild luotu onnistuneesti!', 'Guild created successfully!');
        });
      }
      await _loadGuildData();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (_) {
      if (mounted) setState(() => _error = _t('Guildin luominen epäonnistui.', 'Failed to create Guild.'));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }


  Future<void> _joinGuild() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage(_t('Syötä kutsukoodi.', 'Enter an invite code.'));
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await _functions.httpsCallable('joinGuild').call({'inviteCode': code});
      final data = Map<String, dynamic>.from(result.data as Map);
      _inviteCodeController.clear();
      if (mounted) {
        setState(() {
          _notice = data['message']?.toString() ?? _t('Liityit Guildiin!', 'You joined the Guild!');
        });
      }
      await _loadGuildData();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (_) {
      if (mounted) setState(() => _error = _t('Guildiin liittyminen epäonnistui.', 'Failed to join Guild.'));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }


  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _surface),
    );
  }


  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    _showMessage(_t('Kutsukoodi kopioitu!', 'Invite code copied!'));
  }


  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }


  List<Map<String, dynamic>> _membersFromData() {
    final raw = _guildData?['members'];
    if (raw is List) {
      return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return <Map<String, dynamic>>[];
  }


  String _dateText(dynamic value) {
    DateTime? date;
    if (value is DateTime) date = value;
    if (value is String) date = DateTime.tryParse(value);
    if (value is Map && value['_seconds'] is num) {
      date = DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as num).toInt() * 1000);
    }
    if (date == null) return _t('Ei tietoa', 'Unknown');
    final local = date.toLocal();
    return '${local.day}.${local.month}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        title: Text(_t('Guild-yhteisö', 'Guild Community')),
        actions: [
          IconButton(
            tooltip: _t('Päivitä', 'Refresh'),
            onPressed: _loading ? null : _loadGuildData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _purple))
            : RefreshIndicator(
                color: _purple,
                backgroundColor: _card,
                onRefresh: _loadGuildData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _headerCard(),
                    if (_notice != null) ...[
                      const SizedBox(height: 12),
                      _messageCard(_notice!, success: true),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _messageCard(_error!, success: false),
                    ],
                    const SizedBox(height: 16),
                    if (_isInGuild) _guildDetails() else _joinCreatePanel(),
                  ],
                ),
              ),
      ),
    );
  }


  bool get _isInGuild => _guildData?['inGuild'] == true;


  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_card, _surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.shield_rounded, color: _gold, size: 34),
            SizedBox(width: 10),
            Expanded(child: Text('STELLA GUILDS', style: TextStyle(color: _pink, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
          ]),
          const SizedBox(height: 12),
          Text(
            _t('Yhdessä louhimme vahvemmin.', 'Mine together. Grow stronger.'),
            style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            _t('Guild-bonus kasvattaa louhintatehoa – se ei ole suora STL-palkkio.', 'Guild bonus increases mining power—it is not a direct STL reward.'),
            style: const TextStyle(color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }


  Widget _messageCard(String message, {required bool success}) {
    final color = success ? _green : _red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: _text, height: 1.35))),
        ],
      ),
    );
  }


  Widget _joinCreatePanel() {
    return Column(
      children: [
        _sectionCard(
          icon: Icons.add_circle_outline_rounded,
          title: _t('Luo oma Guild', 'Create a Guild'),
          subtitle: _t('Kokoa oma Stella-tiimisi.', 'Start your own Stella team.'),
          children: [
            TextField(
              controller: _guildNameController,
              maxLength: 24,
              style: const TextStyle(color: _text),
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(_t('Guildin nimi', 'Guild name')),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _creating || _joining ? null : _createGuild,
                style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _background, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _creating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _background)) : const Icon(Icons.rocket_launch_rounded),
                label: Text(_creating ? _t('Luodaan…', 'Creating…') : _t('Luo Guild', 'Create Guild'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          icon: Icons.key_rounded,
          title: _t('Liity Guildiin', 'Join a Guild'),
          subtitle: _t('Liity tiimiin kutsukoodilla.', 'Join a team with an invite code.'),
          children: [
            TextField(
              controller: _inviteCodeController,
              maxLength: 8,
              style: const TextStyle(color: _text, letterSpacing: 1.8, fontWeight: FontWeight.w700),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
              decoration: _inputDecoration(_t('8-merkkinen kutsukoodi', '8-character invite code')),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _joining || _creating ? null : _joinGuild,
                style: OutlinedButton.styleFrom(foregroundColor: _pink, side: const BorderSide(color: _pink), padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _joining ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _pink)) : const Icon(Icons.group_add_rounded),
                label: Text(_joining ? _t('Liitytään…', 'Joining…') : _t('Liity Guildiin', 'Join Guild'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }


  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _background,
      counterStyle: const TextStyle(color: _muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _purple.withValues(alpha: 0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.6)),
    );
  }


  Widget _guildDetails() {
    final guild = _asMap(_guildData?['guild']);
    final members = _membersFromData();
    final name = guild['name']?.toString() ?? 'Guild';
    final invite = guild['inviteCode']?.toString() ?? '';
    final active = (_guildData?['activeMembers'] as num?)?.toInt() ?? 0;
    final totalActive = (_guildData?['totalMembers'] as num?)?.toInt() ?? members.length;
    final bonus = (_guildData?['bonusPercent'] as num?)?.toDouble() ?? 0;
    final maxMembers = (guild['maxMembers'] as num?)?.toInt() ?? 20;
    final role = _guildData?['currentUserRole']?.toString() ?? 'member';
    final window = (_guildData?['activeWindowMinutes'] as num?)?.toInt() ?? 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _purple.withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.shield_rounded, color: _gold, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(color: _text, fontSize: 21, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 8),
              _pill(role == 'leader' ? _t('Guild-johtaja', 'Guild Leader') : _t('Guild-jäsen', 'Guild Member'), _gold),
              const SizedBox(height: 14),
              if (invite.isNotEmpty) _inviteCodeRow(invite),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _statTile(Icons.people_alt_rounded, '$totalActive/$maxMembers', _t('Jäsentä', 'Members'), _pink)),
                const SizedBox(width: 10),
                Expanded(child: _statTile(Icons.bolt_rounded, '$active', _t('Aktiivisia', 'Active'), _green)),
                const SizedBox(width: 10),
                Expanded(child: _statTile(Icons.trending_up_rounded, '+${bonus.toStringAsFixed(bonus % 1 == 0 ? 0 : 1)}%', _t('Bonus', 'Bonus'), _gold)),
              ]),
              const SizedBox(height: 12),
              Text(
                _t('Aktiivisuus tarkistetaan viimeisen $window minuutin ajalta.', 'Activity is checked over the last $window minutes.'),
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          icon: Icons.groups_rounded,
          title: _t('Guildin jäsenet', 'Guild Members'),
          subtitle: _t('${members.length} jäsen', '${members.length} members'),
          children: members.isEmpty
              ? [Text(_t('Jäsenlistaa ei löytynyt.', 'No member list found.'), style: const TextStyle(color: _muted))]
              : members.map(_memberRow).toList(),
        ),
      ],
    );
  }


  Widget _inviteCodeRow(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.vpn_key_rounded, color: _pink),
        const SizedBox(width: 8),
        Expanded(child: Text(code, style: const TextStyle(color: _pink, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16))),
        IconButton(onPressed: () => _copyInviteCode(code), icon: const Icon(Icons.copy_rounded, color: _muted), tooltip: _t('Kopioi', 'Copy')),
      ]),
    );
  }


  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(13)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11)),
      ]),
    );
  }


  Widget _memberRow(Map<String, dynamic> member) {
    final username = member['username']?.toString() ?? _t('Tuntematon jäsen', 'Unknown member');
    final role = member['role']?.toString() ?? 'member';
    final isActive = member['active'] == true;
    final joined = _dateText(member['joinedAt']);
    final lastActive = _dateText(member['lastActiveAt']);
    final isLeader = role == 'leader';
    final color = isLeader ? _gold : (isActive ? _green : _muted);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: color.withValues(alpha: 0.18), child: Icon(isLeader ? Icons.workspace_premium_rounded : Icons.person_rounded, color: color)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(username, style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(isLeader ? _t('Guild-johtaja', 'Guild Leader') : _t('Jäsen', 'Member'), style: TextStyle(color: isLeader ? _gold : _muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(_t('Liittynyt: $joined', 'Joined: $joined'), style: const TextStyle(color: _muted, fontSize: 11)),
          Text(_t('Viimeksi aktiivinen: $lastActive', 'Last active: $lastActive'), style: const TextStyle(color: _muted, fontSize: 11)),
        ])),
        const SizedBox(width: 6),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 10, color: isActive ? _green : _muted),
          const SizedBox(height: 3),
          Text(isActive ? _t('Aktiivinen', 'Active') : _t('Poissa', 'Inactive'), style: TextStyle(color: isActive ? _green : _muted, fontSize: 10)),
        ]),
      ]),
    );
  }


  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }


  Widget _sectionCard({required IconData icon, required String title, required String subtitle, required List<Widget> children})  {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _purple.withValues(alpha: 0.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: _purple), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16))) ]),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}
