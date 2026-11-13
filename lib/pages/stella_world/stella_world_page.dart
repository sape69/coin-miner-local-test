import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stella World - ensimmäinen pelattava näkymä.
///
/// Tämä ensimmäinen versio sisältää yhden sisustettavan huoneen.
/// Sisustusvalinnat ovat tässä vaiheessa sivun muistissa eivätkä vielä
/// tallennu Firebaseen tai käyttäjätilille.
class StellaWorldPage extends StatefulWidget {
  final String languageCode;

  const StellaWorldPage({
    super.key,
    required this.languageCode,
  });

  @override
  State<StellaWorldPage> createState() => _StellaWorldPageState();
}

class _StellaWorldPageState extends State<StellaWorldPage>
    with SingleTickerProviderStateMixin {
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
  late final AnimationController _stellaRestController;

  String get _decorStorageKey {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'stella_world_decor_$userId';
  }

  bool get _isFinnish =>
      widget.languageCode.toLowerCase().startsWith('fi');

  String _text(String fi, String en) => _isFinnish ? fi : en;

  @override
  void initState() {
    super.initState();
    _stellaRestController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _loadDecor();
  }

  @override
  void dispose() {
    _stellaRestController.dispose();
    super.dispose();
  }

  Future<void> _loadDecor() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedDecor = preferences.getStringList(_decorStorageKey);

      if (!mounted) return;

      if (savedDecor != null && savedDecor.length == 3) {
        final wallpaper = int.tryParse(savedDecor[0]) ?? 0;
        final floor = int.tryParse(savedDecor[1]) ?? 0;
        final furniture = int.tryParse(savedDecor[2]) ?? 0;

        setState(() {
          _wallpaper = wallpaper.clamp(0, _wallpapers.length - 1).toInt();
          _floor = floor.clamp(0, _floors.length - 1).toInt();
          _furniture = furniture.clamp(0, 3).toInt();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = _text(
            'Sisustuksen lataaminen epäonnistui.',
            'Could not load your room decoration.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDecor = false);
      }
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
        setState(() {
          _saveError = _text(
            'Sisustuksen tallentaminen epäonnistui.',
            'Could not save your room decoration.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDecor = false);
      }
    }
  }

  void _updateDecor(VoidCallback update) {
    setState(update);
    _saveDecor();
  }

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
    'Laventeli',
    'Vaaleanpunainen',
    'Tähtiyö',
    'Minttu',
  ];

  final List<String> _floorNames = const [
    'Pehmeä matto',
    'Kultainen puu',
    'Yömatto',
    'Metsämatto',
  ];

  final List<String> _furnitureNames = const [
    'Mukava nojatuoli',
    'Vaaleanpunainen sohva',
    'Kuunvalon sohva',
    'Tähtituoli',
  ];

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
            child: const Icon(
              Icons.pets_rounded,
              color: pink,
              size: 34,
            ),
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
                  style: const TextStyle(
                    color: secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoom() {
    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _wallpapers[_wallpaper],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: purple.withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _wallpapers[_wallpaper],
                    _wallpapers[_wallpaper].withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          ..._buildStars(),
          Positioned(
            top: 42,
            left: 22,
            child: Container(
              width: 92,
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFF2C1B49),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.nightlight_round, color: gold, size: 42),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 24,
            child: Icon(
              Icons.star_rounded,
              color: gold.withValues(alpha: 0.9),
              size: 35,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 94,
            child: Container(
              decoration: BoxDecoration(
                color: _floors[_floor],
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 34,
            left: 26,
            child: _buildFurniture(),
          ),
          Positioned(
            bottom: 25,
            right: 34,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3A79),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: const Icon(Icons.toys_rounded, color: pink),
                ),
                const SizedBox(height: 3),
                Container(width: 7, height: 17, color: gold),
              ],
            ),
          ),
          // Piirretty Stella lepää lattialla. Hidas skaalaus luo
          // hienovaraisen hengitysliikkeen ilman, että hahmo vaeltaa huoneessa.
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: AnimatedBuilder(
              animation: _stellaRestController,
              builder: (context, child) {
                final breathing =
                    1.0 + (_stellaRestController.value * 0.025);
                return Transform.scale(
                  scale: breathing,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/stella_sleeping_cartoon.gif',
                    width: 150,
                    height: 118,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 150,
                        height: 118,
                        child: Icon(
                          Icons.pets_rounded,
                          color: primaryText,
                          size: 68,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Stella',
                    style: TextStyle(
                      color: primaryText.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: background.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
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
  }

  List<Widget> _buildStars() {
    const positions = <Offset>[
      Offset(0.42, 0.18),
      Offset(0.72, 0.30),
      Offset(0.58, 0.48),
      Offset(0.88, 0.16),
      Offset(0.34, 0.42),
    ];

    return positions.map((position) {
      return Positioned(
        left: position.dx * 340,
        top: position.dy * 270,
        child: Icon(
          Icons.star_rounded,
          size: 13,
          color: gold.withValues(alpha: 0.75),
        ),
      );
    }).toList();
  }

  Widget _buildFurniture() {
    final List<Color> furnitureColors = const [
      Color(0xFF6C4B91),
      Color(0xFFB96F9C),
      Color(0xFF526D9C),
      Color(0xFF718C82),
    ];

    return Column(
      children: [
        Container(
          width: 112,
          height: 50,
          decoration: BoxDecoration(
            color: furnitureColors[_furniture],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
              bottom: Radius.circular(10),
            ),
            border: Border.all(color: pink.withValues(alpha: 0.8), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.favorite_rounded, color: pink, size: 22),
          ),
        ),
        Row(
          children: [
            Container(
              width: 9,
              height: 18,
              color: const Color(0xFF4B315E),
            ),
            const SizedBox(width: 94),
            Container(
              width: 9,
              height: 18,
              color: const Color(0xFF4B315E),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecorationPanel() {
    final List<String> categories = [
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
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
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
      colors = const [
        Color(0xFF6C4B91),
        Color(0xFFB96F9C),
        Color(0xFF526D9C),
        Color(0xFF718C82),
      ];
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
          final bool isSelected = selected == index;
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
                    style: const TextStyle(
                      color: primaryText,
                      fontSize: 11,
                    ),
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
              style: const TextStyle(
                color: secondaryText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
