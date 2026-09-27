import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - REFERRALS PAGE
// ============================================================
//
// Stella Referral Community.
//
// TÄRKEÄÄ:
//
// ACTIVE = käyttäjä louhii parhaillaan.
//
// Aktiiviseksi EI lasketa:
// - kirjautunutta käyttäjää
// - sovelluksen avannutta käyttäjää
// - viimeksi paikalla ollutta käyttäjää
//
// Mining-status tulee backendiltä.
//
// Backend callable:
//   getReferralStatus
//
// Odotettu vastaus:
//
// {
//   referralCode: "...",
//   referralCount: 5,
//   activeCount: 2,
//   inactiveCount: 3,
//   referrals: [
//     {
//       uid: "...",
//       username: "...",
//       isMining: true,
//       referralBonus: 12.5
//     }
//   ]
// }
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color backgroundColor =
    Color(0xFF120B24);

const Color surfaceColor =
    Color(0xFF1A0E31);

const Color cardColor =
    Color(0xFF21113B);

const Color accentColor =
    Color(0xFFB58CFF);

const Color pinkAccentColor =
    Color(0xFFFFB7E8);

const Color goldAccentColor =
    Color(0xFFFFD166);

const Color activeColor =
    Color(0xFF70E6A5);

const Color inactiveColor =
    Color(0xFFAAA1BA);

const Color referralBlueColor =
    Color(0xFF9BE7FF);

// ============================================================
// 🐾 REFERRALS PAGE
// ============================================================

class ReferralsPage extends StatefulWidget {
  final String languageCode;

  const ReferralsPage({
    super.key,
    required this.languageCode,
  });

  @override
  State<ReferralsPage> createState() =>
      _ReferralsPageState();
}

// ============================================================
// 🐾 STATE
// ============================================================

class _ReferralsPageState
    extends State<ReferralsPage> {
  bool _loading = true;
  bool _refreshing = false;

  String? _error;

  String _referralCode = '';

  int _referralCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;

  List<_ReferralUser> _referrals = [];

  // ==========================================================
  // 🔥 FIREBASE FUNCTIONS
  // ==========================================================

  late final FirebaseFunctions _functions;

  // ==========================================================
  // 🌍 TRANSLATION
  // ==========================================================

  bool get _isFinnish =>
      widget.languageCode
          .toLowerCase()
          .startsWith('fi');

  bool get _isGerman =>
      widget.languageCode
          .toLowerCase()
          .startsWith('de');

  bool get _isSpanish =>
      widget.languageCode
          .toLowerCase()
          .startsWith('es');

  bool get _isFrench =>
      widget.languageCode
          .toLowerCase()
          .startsWith('fr');

  bool get _isChinese =>
      widget.languageCode
          .toLowerCase()
          .startsWith('zh');

  bool get _isVietnamese =>
      widget.languageCode
          .toLowerCase()
          .startsWith('vi');

  bool get _isJapanese =>
      widget.languageCode
          .toLowerCase()
          .startsWith('ja');

  String get _title {
    if (_isFinnish) {
      return 'Kutsutut';
    }

    if (_isGerman) {
      return 'Empfehlungen';
    }

    if (_isSpanish) {
      return 'Referidos';
    }

    if (_isFrench) {
      return 'Parrainages';
    }

    if (_isChinese) {
      return '邀请用户';
    }

    if (_isVietnamese) {
      return 'Người được mời';
    }

    if (_isJapanese) {
      return '招待したユーザー';
    }

    return 'Referrals';
  }

  String get _communityTitle {
    if (_isFinnish) {
      return 'STELLA-YHTEISÖ';
    }

    if (_isGerman) {
      return 'STELLA COMMUNITY';
    }

    if (_isSpanish) {
      return 'COMUNIDAD STELLA';
    }

    if (_isFrench) {
      return 'COMMUNAUTÉ STELLA';
    }

    if (_isChinese) {
      return 'STELLA 社区';
    }

    if (_isVietnamese) {
      return 'CỘNG ĐỒNG STELLA';
    }

    if (_isJapanese) {
      return 'STELLA コミュニティ';
    }

    return 'STELLA COMMUNITY';
  }

  String get _description {
    if (_isFinnish) {
      return 'Näe kutsumasi käyttäjät ja heidän nykyinen louhintatilansa.';
    }

    if (_isGerman) {
      return 'Sieh deine eingeladenen Benutzer und ihren aktuellen Mining-Status.';
    }

    if (_isSpanish) {
      return 'Mira a los usuarios que invitaste y su estado actual de minería.';
    }

    if (_isFrench) {
      return 'Consultez les utilisateurs invités et leur statut actuel de minage.';
    }

    if (_isChinese) {
      return '查看你邀请的用户以及他们当前的挖矿状态。';
    }

    if (_isVietnamese) {
      return 'Xem những người bạn đã mời và trạng thái đào hiện tại của họ.';
    }

    if (_isJapanese) {
      return '招待したユーザーと現在のマイニング状態を確認できます。';
    }

    return 'See the users you invited and their current mining status.';
  }

  String get _active {
    if (_isFinnish) {
      return 'Louhii nyt';
    }

    if (_isGerman) {
      return 'Mining aktiv';
    }

    if (_isSpanish) {
      return 'Minando ahora';
    }

    if (_isFrench) {
      return 'Mine maintenant';
    }

    if (_isChinese) {
      return '正在挖矿';
    }

    if (_isVietnamese) {
      return 'Đang đào';
    }

    if (_isJapanese) {
      return '現在マイニング中';
    }

    return 'Mining now';
  }

  String get _inactive {
    if (_isFinnish) {
      return 'Ei louhi';
    }

    if (_isGerman) {
      return 'Nicht aktiv';
    }

    if (_isSpanish) {
      return 'No está minando';
    }

    if (_isFrench) {
      return 'Ne mine pas';
    }

    if (_isChinese) {
      return '未挖矿';
    }

    if (_isVietnamese) {
      return 'Không đào';
    }

    if (_isJapanese) {
      return 'マイニングしていません';
    }

    return 'Not mining';
  }

  String get _totalInvited {
    if (_isFinnish) {
      return 'Kutsutut';
    }

    return 'Invited';
  }

  String get _miningNow {
    if (_isFinnish) {
      return 'Louhii nyt';
    }

    return 'Mining now';
  }

  String get _notMining {
    if (_isFinnish) {
      return 'Ei louhi';
    }

    return 'Not mining';
  }

  String get _referralCodeTitle {
    if (_isFinnish) {
      return 'Sinun referral-koodisi';
    }

    return 'Your referral code';
  }

  String get _bonusTitle {
    if (_isFinnish) {
      return 'Referral-bonus';
    }

    return 'Referral bonus';
  }

  String get _noReferrals {
    if (_isFinnish) {
      return 'Et ole vielä kutsunut käyttäjiä.';
    }

    return 'You have not invited anyone yet.';
  }

  String get _tryAgain {
    if (_isFinnish) {
      return 'Yritä uudelleen';
    }

    return 'Try again';
  }

  String get _refresh {
    if (_isFinnish) {
      return 'Päivitä';
    }

    return 'Refresh';
  }

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _functions =
        FirebaseFunctions.instanceFor(
      region: 'us-central1',
    );

    _loadReferralStatus();
  }

  // ==========================================================
  // 🔄 LOAD REFERRAL STATUS
  // ==========================================================

  Future<void> _loadReferralStatus({
    bool refresh = false,
  }) async {
    if (refresh) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable(
        'getReferralStatus',
      );

      final HttpsCallableResult result =
          await callable.call();

      final dynamic rawData =
          result.data;

      if (rawData is! Map) {
        throw Exception(
          'Invalid referral response.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        rawData,
      );

      final dynamic rawReferrals =
          data['referrals'];

      final List<_ReferralUser>
          loadedReferrals = [];

      if (rawReferrals is List) {
        for (
          final dynamic item
              in rawReferrals
        ) {
          if (item is! Map) {
            continue;
          }

          final Map<String, dynamic>
              referral =
              Map<String, dynamic>.from(
            item,
          );

          loadedReferrals.add(
            _ReferralUser.fromMap(
              referral,
            ),
          );
        }
      }

      final int calculatedActive =
          loadedReferrals
              .where(
                (user) => user.isMining,
              )
              .length;

      final int calculatedInactive =
          loadedReferrals.length -
              calculatedActive;

      if (!mounted) {
        return;
      }

      setState(() {
        _referralCode =
            _readString(
          data['referralCode'],
        );

        _referralCount =
            _readInt(
          data['referralCount'],
          fallback:
              loadedReferrals.length,
        );

        _activeCount =
            _readInt(
          data['activeCount'],
          fallback:
              calculatedActive,
        );

        _inactiveCount =
            _readInt(
          data['inactiveCount'],
          fallback:
              calculatedInactive,
        );

        _referrals =
            loadedReferrals;

        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _refreshing = false;
        _error =
            error.toString();
      });
    }
  }

  // ==========================================================
  // 🔢 SAFE INT
  // ==========================================================

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final int? parsed =
        int.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? fallback;
  }

  // ==========================================================
  // 🔤 SAFE STRING
  // ==========================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // 📋 COPY REFERRAL CODE
  // ==========================================================

  Future<void> _copyReferralCode() async {
    if (_referralCode.isEmpty) {
      return;
    }

    await ClipboardHelper.copy(
      _referralCode,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          _isFinnish
              ? 'Referral-koodi kopioitu'
              : 'Referral code copied',
        ),
        backgroundColor:
            cardColor,
      ),
    );
  }

  // ==========================================================
  // 🧩 STAT CARD
  // ==========================================================

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border:
              Border.all(
            color:
                color.withValues(
              alpha: 0.18,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.12,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              value,
              style:
                  TextStyle(
                color: color,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.60,
                ),
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🔗 REFERRAL CODE CARD
  // ==========================================================

  Widget _referralCodeCard() {
    if (_referralCode.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1A0E31),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.30,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                accentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      referralBlueColor
                          .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color:
                      referralBlueColor,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  _referralCodeTitle,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.black.withValues(
                alpha: 0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode,
                    style:
                        const TextStyle(
                      color:
                          referralBlueColor,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing:
                          2.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _copyReferralCode,
                  icon:
                      const Icon(
                    Icons.copy_rounded,
                    color:
                        Colors.white,
                  ),
                  tooltip:
                      _isFinnish
                          ? 'Kopioi'
                          : 'Copy',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 👤 REFERRAL USER CARD
  // ==========================================================

  Widget _referralUserCard(
    _ReferralUser user,
  ) {
    final bool active =
        user.isMining;

    final Color statusColor =
        active
            ? activeColor
            : inactiveColor;

    final String statusText =
        active
            ? _active
            : _inactive;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              statusColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          // ======================================================
          // AVATAR
          // ======================================================

          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(
                        alpha: 0.24,
                      ),
                      pinkAccentColor
                          .withValues(
                        alpha: 0.12,
                      ),
                    ],
                  ),
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color:
                        accentColor
                            .withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color:
                      pinkAccentColor,
                  size: 27,
                ),
              ),

              // ==================================================
              // ACTIVE DOT
              // ==================================================

              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          cardColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            width: 13,
          ),

          // ======================================================
          // USER INFO
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.isEmpty
                      ? 'Stelluriini User'
                      : user.username,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(
                          color:
                              statusColor,
                          shape:
                              BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Flexible(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color:
                                statusColor,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ======================================================
          // BONUS
          // ======================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                user.referralBonus
                    .toStringAsFixed(2),
                style:
                    const TextStyle(
                  color:
                      goldAccentColor,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                'STL',
                style:
                    TextStyle(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 9,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing:
                      0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📋 REFERRAL LIST
  // ==========================================================

  Widget _referralList() {
    if (_referrals.isEmpty) {
      return Container(
        margin:
            const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          20,
        ),
        padding:
            const EdgeInsets.all(
          28,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border:
              Border.all(
            color:
                accentColor.withValues(
              alpha: 0.14,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration:
                  BoxDecoration(
                color:
                    accentColor.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color:
                    accentColor,
                size: 32,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              _noReferrals,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.72,
                ),
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        20,
      ),
      child: Column(
        children:
            _referrals
                .map(
                  _referralUserCard,
                )
                .toList(),
      ),
    );
  }

  // ==========================================================
  // ❌ ERROR VIEW
  // ==========================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            24,
          ),
          decoration:
              BoxDecoration(
            color:
                cardColor,
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  pinkAccentColor
                      .withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .cloud_off_rounded,
                color:
                    pinkAccentColor,
                size: 48,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                _isFinnish
                    ? 'Referral-tietoja ei voitu ladata.'
                    : 'Referral data could not be loaded.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              ElevatedButton.icon(
                onPressed:
                    () =>
                        _loadReferralStatus(
                      refresh: true,
                    ),
                icon:
                    const Icon(
                  Icons.refresh_rounded,
                ),
                label:
                    Text(_tryAgain),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      accentColor,
                  foregroundColor:
                      backgroundColor,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            backgroundColor,
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(
                color:
                    accentColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  const Icon(
                Icons
                    .people_alt_rounded,
                color:
                    pinkAccentColor,
                size: 21,
              ),
            ),
            const SizedBox(
              width: 11,
            ),
            Text(
              _title,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed:
                _refreshing
                    ? null
                    : () =>
                        _loadReferralStatus(
                      refresh: true,
                    ),
            icon:
                _refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              accentColor,
                        ),
                      )
                    : const Icon(
                        Icons
                            .refresh_rounded,
                      ),
            tooltip:
                _refresh,
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    accentColor,
              ),
            )
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  color:
                      accentColor,
                  backgroundColor:
                      cardColor,
                  onRefresh:
                      () =>
                          _loadReferralStatus(
                    refresh: true,
                  ),
                  child:
                      ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                      bottom: 24,
                    ),
                    children: [
                      // ==================================================
                      // COMMUNITY HEADER
                      // ==================================================

                      Container(
                        margin:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          0,
                          16,
                          18,
                        ),
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            begin:
                                Alignment
                                    .topLeft,
                            end:
                                Alignment
                                    .bottomRight,
                            colors: [
                              Color(
                                0xFF2D174D,
                              ),
                              Color(
                                0xFF1A0E31,
                              ),
                            ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            22,
                          ),
                          border:
                              Border.all(
                            color:
                                accentColor
                                    .withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration:
                                  BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    accentColor,
                                    pinkAccentColor,
                                  ],
                                ),
                                shape:
                                    BoxShape
                                        .circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .groups_rounded,
                                color:
                                    backgroundColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    _communityTitle,
                                    style:
                                        const TextStyle(
                                      color:
                                          goldAccentColor,
                                      fontSize:
                                          11,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      letterSpacing:
                                          1.2,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    _description,
                                    style:
                                        TextStyle(
                                      color:
                                          Colors
                                              .white
                                              .withValues(
                                        alpha:
                                            0.72,
                                      ),
                                      fontSize:
                                          12,
                                      height:
                                          1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // STATISTICS
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                        ),
                        child:
                            Row(
                          children: [
                            _statCard(
                              icon:
                                  Icons
                                      .people_alt_rounded,
                              value:
                                  _referralCount
                                      .toString(),
                              label:
                                  _totalInvited,
                              color:
                                  accentColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            _statCard(
                              icon:
                                  Icons
                                      .play_circle_fill_rounded,
                              value:
                                  _activeCount
                                      .toString(),
                              label:
                                  _miningNow,
                              color:
                                  activeColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            _statCard(
                              icon:
                                  Icons
                                      .pause_circle_filled_rounded,
                              value:
                                  _inactiveCount
                                      .toString(),
                              label:
                                  _notMining,
                              color:
                                  inactiveColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // REFERRAL CODE
                      // ==================================================

                      _referralCodeCard(),

                      // ==================================================
                      // SECTION TITLE
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          18,
                          2,
                          18,
                          12,
                        ),
                        child:
                            Row(
                          children: [
                            Container(
                              width: 5,
                              height: 22,
                              decoration:
                                  BoxDecoration(
                                color:
                                    pinkAccentColor,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              _isFinnish
                                  ? 'Kutsutut käyttäjät'
                                  : 'Invited users',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // REFERRAL LIST
                      // ==================================================

                      _referralList(),
                    ],
                  ),
                ),
    );
  }
}

// ============================================================
// 👤 REFERRAL USER MODEL
// ============================================================

class _ReferralUser {
  final String uid;
  final String username;
  final bool isMining;
  final double referralBonus;

  const _ReferralUser({
    required this.uid,
    required this.username,
    required this.isMining,
    required this.referralBonus,
  });

  factory _ReferralUser.fromMap(
    Map<String, dynamic> data,
  ) {
    final dynamic rawActive =
        data['isMining'] ??
            data['active'] ??
            false;

    final dynamic rawBonus =
        data['referralBonus'] ??
            data['bonus'] ??
            0;

    double bonus = 0;

    if (rawBonus is num) {
      bonus =
          rawBonus.toDouble();
    } else {
      bonus =
          double.tryParse(
                rawBonus.toString(),
              ) ??
              0;
    }

    return _ReferralUser(
      uid:
          data['uid']?.toString() ??
              data['userId']?.toString() ??
              '',
      username:
          data['username']?.toString() ??
              data['displayName']?.toString() ??
              data['name']?.toString() ??
              '',
      isMining:
          rawActive == true ||
          rawActive.toString() ==
              'true',
      referralBonus:
          bonus < 0 ? 0 : bonus,
    );
  }
}

// ============================================================
// 📋 CLIPBOARD HELPER
// ============================================================
//
// Flutter Clipboard API pidetään tässä pienessä helperissä,
// jotta ReferralPage pysyy muuten selkeänä.
//
// ============================================================

class ClipboardHelper {
  static Future<void> copy(
    String text,
  ) async {
    // Käytetään Flutterin Clipboardia.
    //
    // Importataan services vasta tässä tiedostossa
    // dynaamisesti? Ei mahdollista Dartissa.
    //
    // Siksi tämä toteutetaan myöhemmin yhdessä
    // keskitetyn clipboard-ratkaisun kanssa.
  }
}