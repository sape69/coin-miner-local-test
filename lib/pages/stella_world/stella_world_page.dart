import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../achievements/achievements_service.dart';

/// Stella World - yksi sisustettava huone.
class StellaWorldPage extends StatefulWidget {
  final String languageCode;

  const StellaWorldPage({
    super.key,
    required this.languageCode,
  });

  @override
  State<StellaWorldPage> createState() => _StellaWorldPageState();
}

class _StellaWorldPageState extends State<StellaWorldPage> {
  static const Color background = Color(0xFF120B24);
  static const Color surface = Color(0xFF1A0E31);
  static const Color card = Color(0xFF21113B);
  static const Color purple = Color(0xFFB58CFF);
  static const Color pink = Color(0xFFFFB7E8);
  static const Color gold = Color(0xFFFFD166);
  static const Color primaryText = Color(0xFFF8F4FF);
  static const Color secondaryText = Color(0xFFBDB4D1);

  int _selectedCategory = 0;
  int _wallpaper = 0;
  int _floor = 0;
  int _furniture = 0;
  bool _isLoadingDecor = true;
  bool _isSavingDecor = false;
  String? _saveError;

  final AchievementsService _achievementsService = AchievementsService();
  int _completedAchievementCount = 0;
  bool _isLoadingAchievements = true;
  String? _achievementError;

  String get _decorStorageKey {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'stella_world_decor_$userId';
  }

  bool get _isFinnish => widget.languageCode.toLowerCase().startsWith('fi');
  String _text(String fi, String en) => _isFinnish ? fi : en;

  final List<Color> _wallpapers = const [
    Color(0xFF8060B8),
    Color(0xFFB76D9D),
    Color(0xFF527D9C),
    Color(0xFF6D927F),
  ];

  final List<Color> _floors = const [
    Color(0xFF8B6380),
    Color(0xFFB58A68),
    Color(0xFF69618E),
    Color(0xFF6D827B),
  ];

  final List<String> _wallpaperNames = const [
    'Laventeli', 'Vaaleanpunainen', 'Tähtiyö', 'Minttu',
  ];
  final List<String> _floorNames = const [
    'Pehmeä matto', 'Kultainen puu', 'Yömatto', 'Metsämatto',
  ];
  final List<String> _furnitureNames = const [
    'Mukava nojatuoli', 'Vaaleanpunainen sohva',
    'Kuunvalon sohva', 'Tähtituoli',
  ];

  static const List<Color> _furnitureColors = [
    Color(0xFF6C4B91),
    Color(0xFFB96F9C),
    Color(0xFF526D9C),
    Color(0xFF718C82),
  ];

  @override
  void initState() {
    super.initState();
    _loadDecor();
    _loadAchievementCount();
  }

  Future<void> _loadAchievementCount() async {
    try {
      final count = await _achievementsService.getCompletedCount();
      if (!mounted) return;
      setState(() {
        _completedAchievementCount = count < 0 ? 0 : count;
        _achievementError = null;
        _isLoadingAchievements = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _achievementError = _text(
          'Saavutusten lataaminen epäonnistui. Yritä päivittää.',
          'Could not load achievements. Please refresh.',
        );
        _isLoadingAchievements = false;
      });
    }
  }

  Future<void> _loadDecor() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getStringList(_decorStorageKey);
      if (!mounted) return;

      if (saved != null && saved.length >= 3) {
        setState(() {
          _wallpaper =
              (int.tryParse(saved[0]) ?? 0).clamp(0, _wallpapers.length - 1);
          _floor = (int.tryParse(saved[1]) ?? 0).clamp(0, _floors.length - 1);
          _furniture = (int.tryParse(saved[2]) ?? 0).clamp(0, 3);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = _text(
          'Sisustuksen lataaminen epäonnistui.',
          'Could not load your room decoration.',
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingDecor = false);
    }
  }

  Future<void> _saveDecor() async {
    if (_isLoadingDecor) return;
    setState(() {
      _isSavingDecor = true;
      _saveError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_decorStorageKey, [
        _wallpaper.toString(),
        _floor.toString(),
        _furniture.toString(),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = _text(
          'Sisustuksen tallentaminen epäonnistui.',
          'Could not save your room decoration.',
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingDecor = false);
    }
  }

  void _updateDecor(VoidCallback update) {
    setState(update);
    _saveDecor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: primaryText,
        elevation: 0,
        title: Text(
          _text('Stella-maailma', 'Stella World'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildRoom(),
            const SizedBox(height: 18),
            _buildAchievementRewardsCard(),
            const SizedBox(height: 18),
            _buildDecorationPanel(),
            const SizedBox(height: 14),
            _buildComingSoonCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38245D), Color(0xFF21113B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: pink.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, color: pink, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Tervetuloa Stellan kotiin!', 'Welcome to Stella’s home!'),
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _text(
                    'Tutki, sisusta ja rakenna oma pieni tähtimaailmasi.',
                    'Explore, decorate and build your own little star world.',
                  ),
                  style: const TextStyle(color: secondaryText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoom() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomWidth = constraints.maxWidth;
        return Container(
          height: 330,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _wallpapers[_wallpaper],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: purple.withValues(alpha: 0.55), width: 2),
            boxShadow: [
              BoxShadow(
                color: purple.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/stella_room_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _wallpapers[_wallpaper],
                        _wallpapers[_wallpaper].withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 94,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _floors[_floor].withValues(alpha: 0.34),
                    border: Border(
                      top: BorderSide(
                        color: pink.withValues(alpha: 0.48),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // Perusmatto kuuluu huoneeseen heti alusta alkaen.
              Positioned(
                left: roomWidth * 0.285,
                bottom: 8,
                child: _buildStarRug(),
              ),
              if (_completedAchievementCount >= 5)
                Positioned(
                  left: roomWidth * 0.31,
                  bottom: 48,
                  child: _buildGoldStarRug(),
                ),
              if (_completedAchievementCount >= 10)
                Positioned(
                  left: roomWidth * 0.24,
                  bottom: 104,
                  child: _buildPinkCatTree(),
                ),
              if (_completedAchievementCount >= 20)
                Positioned(
                  top: 12,
                  right: roomWidth * 0.38,
                  child: _buildCrystalChandelier(),
                ),

              // Stellan uusi raapimapuu sijoitetaan huoneen vasemmalle puolelle.
              Positioned(
                left: roomWidth * 0.045,
                bottom: 104,
                child: _buildScratchingPost(),
              ),
              Positioned(
                bottom: 27,
                left: roomWidth * 0.07,
                child: _buildFurniture(),
              ),

              // Stellan uusi oma peti.
              Positioned(
                bottom: 13,
                left: roomWidth * 0.47,
                child: _buildCatBed(),
              ),

              Positioned(
                right: roomWidth * 0.075,
                bottom: 8,
                child: Container(
                  width: roomWidth * 0.27,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF160D25).withValues(alpha: 0.48),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(roomWidth * 0.14, 8),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: roomWidth * 0.045,
                bottom: 5,
                width: roomWidth * 0.31,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/stella_sleeping_cartoon.gif',
                      width: roomWidth * 0.29,
                      height: 92,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                        width: 104,
                        height: 82,
                        child: Icon(
                          Icons.pets_rounded,
                          color: primaryText,
                          size: 62,
                        ),
                      ),
                    ),
                    Text(
                      'Stella',
                      style: TextStyle(
                        color: primaryText.withValues(alpha: 0.98),
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: background.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pink.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    _text('Stellan koti', 'Stella’s home'),
                    style: const TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementRewardsCard() {
    final rewards = [
      (5, 'Kultainen tähtimatto', 'Gold Star Rug', Icons.star_rounded),
      (10, 'Vaaleanpunainen kissapuu', 'Pink Cat Tree', Icons.pets_rounded),
      (20, 'Kristallikruunu', 'Crystal Chandelier', Icons.diamond_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: gold, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text('Tehtävien erikoispalkinnot', 'Achievement rewards'),
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: _text('Päivitä saavutukset', 'Refresh achievements'),
                onPressed: _isLoadingAchievements ? null : _loadAchievementCount,
                icon: const Icon(Icons.refresh_rounded, color: purple),
              ),
            ],
          ),
          Text(
            _isLoadingAchievements
                ? _text('Haetaan saavutuksia palvelimelta...', 'Loading achievements from server...')
                : _achievementError ?? _text(
                    'Valmiita saavutuksia: $_completedAchievementCount',
                    'Completed achievements: $_completedAchievementCount',
                  ),
            style: const TextStyle(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...rewards.map((reward) {
            final int threshold = reward.$1;
            final bool unlocked = _completedAchievementCount >= threshold;
            final int progress = _completedAchievementCount >= threshold
                ? threshold
                : _completedAchievementCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: unlocked ? gold.withValues(alpha: 0.65) : secondaryText.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(unlocked ? reward.$4 : Icons.lock_rounded,
                        color: unlocked ? gold : secondaryText, size: 25),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFinnish ? reward.$2 : reward.$3,
                            style: TextStyle(
                              color: unlocked ? primaryText : secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            unlocked
                                ? _text('Avattu – koriste näkyy huoneessa', 'Unlocked – decoration is in the room')
                                : _text('$progress / $threshold saavutusta', '$progress / $threshold achievements'),
                            style: const TextStyle(color: secondaryText, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: (progress / threshold).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: background,
                              valueColor: AlwaysStoppedAnimation<Color>(unlocked ? gold : purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                        color: unlocked ? gold : secondaryText, size: 19),
                  ],
                ),
              ),
            );
          }),
          if (_achievementError != null)
            TextButton.icon(
              onPressed: _loadAchievementCount,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Yritä uudelleen', 'Try again')),
            ),
        ],
      ),
    );
  }

  Widget _buildGoldStarRug() {
    return Container(
      width: 72,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFFFE7A3), Color(0xFFD69B32), Color(0xFF8D5C22),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFF0BC), width: 2),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.45), blurRadius: 9)],
      ),
      child: const Icon(Icons.star_rounded, color: Color(0xFF8D5C22), size: 22),
    );
  }

  Widget _buildPinkCatTree() {
    return SizedBox(
      width: 45,
      height: 88,
      child: Stack(
        children: [
          Positioned(
            bottom: 1, left: 2, right: 2,
            child: Container(
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB7E8),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white70),
              ),
            ),
          ),
          Positioned(
            bottom: 11, left: 17, width: 11, height: 59,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDDA4C9),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFFFE4F5)),
              ),
            ),
          ),
          Positioned(
            top: 5, left: 3, right: 3,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFE0F2), Color(0xFFE89BCB)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.pets_rounded, color: Color(0xFF8C62B5), size: 17),
            ),
          ),
          const Positioned(
            right: 0, top: 35,
            child: Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalChandelier() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 2, height: 13, color: const Color(0xFFFFE6A5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFB58CFF).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE6A5), width: 1.5),
            boxShadow: [BoxShadow(color: purple.withValues(alpha: 0.65), blurRadius: 12)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.diamond_rounded, color: Colors.white, size: 14),
              Icon(Icons.diamond_rounded, color: Color(0xFFFFE6A5), size: 18),
              Icon(Icons.diamond_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStarRug() {
    return SizedBox(
      width: 132,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7652A6), Color(0xFF39245F)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: pink.withValues(alpha: 0.88),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 7,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome_rounded,
            color: gold.withValues(alpha: 0.96),
            size: 24,
          ),
          Positioned(
            left: 19,
            top: 15,
            child: Icon(
              Icons.star_rounded,
              color: pink.withValues(alpha: 0.95),
              size: 13,
            ),
          ),
          Positioned(
            right: 19,
            top: 15,
            child: Icon(
              Icons.star_rounded,
              color: pink.withValues(alpha: 0.95),
              size: 13,
            ),
          ),
          Positioned(
            bottom: 2,
            child: Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchingPost() {
    return SizedBox(
      width: 66,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pyöreä, tukeva jalusta.
          Positioned(
            left: 2,
            right: 2,
            bottom: 2,
            child: Container(
              height: 15,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD7EF), Color(0xFF9B6ABF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE8F8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // Raapimapuun sisal-pylväs.
          Positioned(
            left: 25,
            bottom: 14,
            width: 16,
            height: 76,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8C59E), Color(0xFFB98B65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFFFFE3C3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 3,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 2,
                  height: 65,
                  color: const Color(0xFF8F684F).withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          // Ylempi taso.
          Positioned(
            left: 9,
            top: 20,
            width: 48,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD8F0), Color(0xFFB58CFF)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFECFA), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Pieni pesä ylimmällä tasolla.
          Positioned(
            left: 5,
            top: 4,
            width: 56,
            height: 22,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE6F6), Color(0xFFE3B9F0)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pink, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.pets_rounded, color: Color(0xFF8C62B5), size: 16),
              ),
            ),
          ),
          // Roikkuva tähtilelu ja naru.
          Positioned(
            right: 4,
            top: 31,
            child: Container(
              width: 1.5,
              height: 22,
              color: const Color(0xFFFFE3A1),
            ),
          ),
          Positioned(
            right: 0,
            top: 49,
            child: Icon(
              Icons.star_rounded,
              color: gold,
              size: 15,
              shadows: [
                Shadow(
                  color: gold.withValues(alpha: 0.65),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          // Pienet koristeelliset tassunjäljet jalustassa.
          const Positioned(
            left: 12,
            bottom: 5,
            child: Icon(Icons.pets_rounded, color: Color(0xFF80579F), size: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildCatBed() {
    return SizedBox(
      width: 86,
      height: 59,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 1,
            left: 5,
            right: 5,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF160D25).withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Pedin pehmeä ulkoreuna.
          Positioned(
            bottom: 5,
            child: Container(
              width: 84,
              height: 43,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD0EE),
                    Color(0xFFB77AD8),
                    Color(0xFF754B9D),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFFFE5F7), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: pink.withValues(alpha: 0.20),
                    blurRadius: 9,
                  ),
                ],
              ),
            ),
          ),
          // Sisäpehmuste.
          Positioned(
            bottom: 11,
            child: Container(
              width: 62,
              height: 29,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0FA), Color(0xFFE9BCEB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDCA5E5),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFFB58CFF),
                  size: 22,
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 10,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: gold.withValues(alpha: 0.95),
              size: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurniture() {
    final sofaColor = _furnitureColors[_furniture];
    return SizedBox(
      width: 158,
      height: 91,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 9,
            right: 9,
            bottom: 3,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF160D25).withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 2,
            height: 57,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(sofaColor, Colors.white, 0.28)!,
                    Color.lerp(sofaColor, Colors.white, 0.08)!,
                    Color.lerp(sofaColor, Colors.black, 0.16)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: pink.withValues(alpha: 0.95), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: pink.withValues(alpha: 0.14),
                    blurRadius: 9,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 11,
            width: 1.5,
            height: 34,
            child: Container(color: Colors.white.withValues(alpha: 0.20)),
          ),
          Positioned(
            right: 34,
            top: 11,
            width: 1.5,
            height: 34,
            child: Container(color: Colors.white.withValues(alpha: 0.20)),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: 43,
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(sofaColor, Colors.white, 0.20)!,
                    sofaColor,
                    Color.lerp(sofaColor, Colors.black, 0.10)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Color.lerp(sofaColor, Colors.white, 0.40)!,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 34,
                  height: 25,
                  decoration: BoxDecoration(
                    color: pink.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: pink.withValues(alpha: 0.58)),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: pink, size: 18),
                ),
              ),
            ),
          ),
          Positioned(left: 0, top: 37, width: 20, height: 42, child: _sofaArm(sofaColor)),
          Positioned(right: 0, top: 37, width: 20, height: 42, child: _sofaArm(sofaColor)),
          Positioned(left: 14, bottom: 0, child: _sofaLeg()),
          Positioned(right: 14, bottom: 0, child: _sofaLeg()),
          Positioned(
            right: 25,
            top: 49,
            child: Icon(Icons.auto_awesome_rounded, size: 11, color: gold.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }

  Widget _sofaArm(Color sofaColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(sofaColor, Colors.white, 0.30)!,
            sofaColor,
            Color.lerp(sofaColor, Colors.black, 0.18)!,
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: pink.withValues(alpha: 0.92), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _sofaLeg() {
    return Container(
      width: 9,
      height: 13,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD98A), Color(0xFF9B633E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorationPanel() {
    final categories = [
      _text('Seinät', 'Walls'),
      _text('Lattia', 'Floor'),
      _text('Kalusteet', 'Furniture'),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Sisusta Stellan huone', 'Decorate Stella’s room'),
            style: const TextStyle(
              color: primaryText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(categories.length, (index) {
              final selected = _selectedCategory == index;
              return ChoiceChip(
                label: Text(categories[index]),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = index),
                selectedColor: purple,
                backgroundColor: surface,
                labelStyle: TextStyle(
                  color: selected ? background : primaryText,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected ? purple : secondaryText.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          _buildOptions(),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _isSavingDecor
                    ? Icons.sync_rounded
                    : _saveError != null
                        ? Icons.warning_amber_rounded
                        : Icons.cloud_done_rounded,
                size: 16,
                color: _saveError != null ? pink : gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _isLoadingDecor
                      ? _text('Ladataan sisustusta...', 'Loading decoration...')
                      : _saveError ??
                          (_isSavingDecor
                              ? _text('Tallennetaan...', 'Saving...')
                              : _text(
                                  'Sisustus tallennettu tähän laitteeseen',
                                  'Decoration saved on this device',
                                )),
                  style: const TextStyle(color: secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final List<Color> colors;
    final List<String> names;
    final int selected;

    if (_selectedCategory == 0) {
      colors = _wallpapers;
      names = _wallpaperNames;
      selected = _wallpaper;
    } else if (_selectedCategory == 1) {
      colors = _floors;
      names = _floorNames;
      selected = _floor;
    } else {
      colors = _furnitureColors;
      names = _furnitureNames;
      selected = _furniture;
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = selected == index;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _updateDecor(() {
                if (_selectedCategory == 0) {
                  _wallpaper = index;
                } else if (_selectedCategory == 1) {
                  _floor = index;
                } else {
                  _furniture = index;
                }
              });
            },
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? gold : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_circle, color: primaryText)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    names[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: primaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: gold, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _text(
                'Seuraavaksi Stella pääsee tutkimaan kristallikaivosta ja tähtimetsää!',
                'Next, Stella will explore the Crystal Mine and the Star Forest!',
              ),
              style: const TextStyle(color: secondaryText, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
