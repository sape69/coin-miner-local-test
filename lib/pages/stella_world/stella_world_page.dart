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
    _loadDecor();
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
            border: Border.all(
              color: purple.withValues(alpha: 0.55),
              width: 2,
            ),
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
              // Yksityiskohtainen taustakuva: ikkuna, tähtitaivas,
              // verhot, kasvit ja lämmin huonevalaistus.
              Image.asset(
                'assets/images/stella_room_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
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
                  );
                },
              ),
              // Valittu lattiasävy lisätään läpikuultavana kerroksena,
              // jotta taustakuvan puulattian yksityiskohdat säilyvät.
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
              // Kalusteet ovat erillisiä Flutter-elementtejä taustasta.
              Positioned(
                bottom: 27,
                left: roomWidth * 0.07,
                child: _buildFurniture(),
              ),
              // Lelut sijoitetaan huoneen keskiosaan, jotta ne eivät
              // mene Stellan tai sohvan päälle.
              Positioned(
                bottom: 22,
                right: roomWidth * 0.36,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D3A79),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pink, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: pink.withValues(alpha: 0.22),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.toys_rounded,
                        color: pink,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(width: 7, height: 13, color: gold),
                  ],
                ),
              ),
              // Stellan pehmeä varjo osuu lattiaan ja luo vaikutelman,
              // että hän lepää lattialla eikä leiju ilmassa.
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
              // Stella on lattian oikealla puolella, erillään sohvasta.
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
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 104,
                          height: 82,
                          child: Icon(
                            Icons.pets_rounded,
                            color: primaryText,
                            size: 62,
                          ),
                        );
                      },
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
                    border: Border.all(
                      color: pink.withValues(alpha: 0.45),
                    ),
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
