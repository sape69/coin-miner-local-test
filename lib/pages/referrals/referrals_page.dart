import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// 🐱 STELLURIINI - REFERRALS PAGE
// ============================================================
//
// Stella Referral Community.
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
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color surfaceColor = Color(0xFF1A0E31);
const Color cardColor = Color(0xFF21113B);

const Color accentColor = Color(0xFFB58CFF);
const Color pinkAccentColor = Color(0xFFFFB7E8);
const Color goldAccentColor = Color(0xFFFFD166);

const Color activeColor = Color(0xFF70E6A5);
const Color inactiveColor = Color(0xFFAAA1BA);
const Color referralBlueColor = Color(0xFF9BE7FF);

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
  State<ReferralsPage> createState() => _ReferralsPageState();
}

// ============================================================
// 🐾 STATE
// ============================================================

class _ReferralsPageState extends State<ReferralsPage> {
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
  // 🌍 LANGUAGE
  // ==========================================================

  String get _language => widget.languageCode.toLowerCase();

  bool get _isFinnish => _language.startsWith('fi');
  bool get _isGerman => _language.startsWith('de');
  bool get _isSpanish => _language.startsWith('es');
  bool get _isFrench => _language.startsWith('fr');
  bool get _isChinese => _language.startsWith('zh');
  bool get _isVietnamese => _language.startsWith('vi');
  bool get _isJapanese => _language.startsWith('ja');

  // ==========================================================
  // 📝 TRANSLATIONS
  // ==========================================================

  String get _title {
    if (_isFinnish) return 'Kutsutut';
    if (_isGerman) return 'Empfehlungen';
    if (_isSpanish) return 'Referidos';
    if (_isFrench) return 'Parrainages';
    if (_isChinese) return '邀请用户';
    if (_isVietnamese) return 'Người được mời';
    if (_isJapanese) return '招待したユーザー';

    return 'Referrals';
  }

  String get _communityTitle {
    if (_isFinnish) return 'STELLA-YHTEISÖ';
    if (_isGerman) return 'STELLA COMMUNITY';
    if (_isSpanish) return 'COMUNIDAD STELLA';
    if (_isFrench) return 'COMMUNAUTÉ STELLA';
    if (_isChinese) return 'STELLA 社区';
    if (_isVietnamese) return 'CỘNG ĐỒNG STELLA';
    if (_isJapanese) return 'STELLA コミュニティ';

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
    if (_isFinnish) return 'Louhii nyt';
    if (_isGerman) return 'Mining aktiv';
    if (_isSpanish) return 'Minando ahora';
    if (_isFrench) return 'Mine maintenant';
    if (_isChinese) return '正在挖矿';
    if (_isVietnamese) return 'Đang đào';
    if (_isJapanese) return '現在マイニング中';

    return 'Mining now';
  }

  String get _inactive {
    if (_isFinnish) return 'Ei louhi';
    if (_isGerman) return 'Nicht aktiv';
    if (_isSpanish) return 'No está minando';
    if (_isFrench) return 'Ne mine pas';
    if (_isChinese) return '未挖矿';
    if (_isVietnamese) return 'Không đào';
    if (_isJapanese) return 'マイニングしていません';

    return 'Not mining';
  }

  String get _totalInvited {
    if (_isFinnish) return 'Kutsutut';
    if (_isGerman) return 'Eingeladen';
    if (_isSpanish) return 'Invitados';
    if (_isFrench) return 'Invités';
    if (_isChinese) return '已邀请';
    if (_isVietnamese) return 'Đã mời';
    if (_isJapanese) return '招待済み';

    return 'Invited';
  }

  String get _miningNow {
    if (_isFinnish) return 'Louhii nyt';
    if (_isGerman) return 'Mining aktiv';
    if (_isSpanish) return 'Minando ahora';
    if (_isFrench) return 'Mine maintenant';
    if (_isChinese) return '正在挖矿';
    if (_isVietnamese) return 'Đang đào';
    if (_isJapanese) return '現在マイニング中';

    return 'Mining now';
  }

  String get _notMining {
    if (_isFinnish) return 'Ei louhi';
    if (_isGerman) return 'Nicht aktiv';
    if (_isSpanish) return 'No está minando';
    if (_isFrench) return 'Ne mine pas';
    if (_isChinese) return '未挖矿';
    if (_isVietnamese) return 'Không đào';
    if (_isJapanese) return 'マイニングしていません';

    return 'Not mining';
  }

  String get _referralCodeTitle {
    if (_isFinnish) return 'Sinun kutsukoodisi';
    if (_isGerman) return 'Dein Empfehlungscode';
    if (_isSpanish) return 'Tu código de invitación';
    if (_isFrench) return 'Votre code d’invitation';
    if (_isChinese) return '你的邀请代码';
    if (_isVietnamese) return 'Mã mời của bạn';
    if (_isJapanese) return 'あなたの招待コード';

    return 'Your invitation code';
  }

  String get _noReferrals {
    if (_isFinnish) {
      return 'Et ole vielä kutsunut käyttäjiä.';
    }

    if (_isGerman) {
      return 'Du hast noch niemanden eingeladen.';
    }

    if (_isSpanish) {
      return 'Todavía no has invitado a nadie.';
    }

    if (_isFrench) {
      return 'Vous n’avez encore invité personne.';
    }

    if (_isChinese) {
      return '你还没有邀请任何用户。';
    }

    if (_isVietnamese) {
      return 'Bạn chưa mời người dùng nào.';
    }

    if (_isJapanese) {
      return 'まだ誰も招待していません。';
    }

    return 'You have not invited anyone yet.';
  }

  String get _tryAgain {
    if (_isFinnish) return 'Yritä uudelleen';
    if (_isGerman) return 'Erneut versuchen';
    if (_isSpanish) return 'Intentar de nuevo';
    if (_isFrench) return 'Réessayer';
    if (_isChinese) return '重试';
    if (_isVietnamese) return 'Thử lại';
    if (_isJapanese) return '再試行';

    return 'Try again';
  }

  String get _refresh {
    if (_isFinnish) return 'Päivitä';
    if (_isGerman) return 'Aktualisieren';
    if (_isSpanish) return 'Actualizar';
    if (_isFrench) return 'Actualiser';
    if (_isChinese) return '刷新';
    if (_isVietnamese) return 'Làm mới';
    if (_isJapanese) return '更新';

    return 'Refresh';
  }

  String get _copy {
    if (_isFinnish) return 'Kopioi';
    if (_isGerman) return 'Kopieren';
    if (_isSpanish) return 'Copiar';
    if (_isFrench) return 'Copier';
    if (_isChinese) return '复制';
    if (_isVietnamese) return 'Sao chép';
    if (_isJapanese) return 'コピー';

    return 'Copy';
  }

  String get _copied {
    if (_isFinnish) return 'Kutsukoodi kopioitu';
    if (_isGerman) return 'Empfehlungscode kopiert';
    if (_isSpanish) return 'Código de invitación copiado';
    if (_isFrench) return 'Code d’invitation copié';
    if (_isChinese) return '邀请代码已复制';
    if (_isVietnamese) return 'Đã sao chép mã mời';
    if (_isJapanese) return '招待コードをコピーしました';

    return 'Invitation code copied';
  }

  String get _copyError {
    if (_isFinnish) return 'Koodin kopiointi epäonnistui';
    if (_isGerman) return 'Der Code konnte nicht kopiert werden';
    if (_isSpanish) return 'No se pudo copiar el código';
    if (_isFrench) return 'Impossible de copier le code';
    if (_isChinese) return '无法复制代码';
    if (_isVietnamese) return 'Không thể sao chép mã';
    if (_isJapanese) return 'コードをコピーできませんでした';

    return 'Could not copy the code';
  }

  String get _invitedUsers {
    if (_isFinnish) return 'Kutsutut käyttäjät';
    if (_isGerman) return 'Eingeladene Benutzer';
    if (_isSpanish) return 'Usuarios invitados';
    if (_isFrench) return 'Utilisateurs invités';
    if (_isChinese) return '已邀请用户';
    if (_isVietnamese) return 'Người dùng đã mời';
    if (_isJapanese) return '招待したユーザー';

    return 'Invited users';
  }

  String get _loadError {
    if (_isFinnish) {
      return 'Kutsutietoja ei voitu ladata.';
    }

    if (_isGerman) {
      return 'Empfehlungsdaten konnten nicht geladen werden.';
    }

    if (_isSpanish) {
      return 'No se pudieron cargar los datos de referidos.';
    }

    if (_isFrench) {
      return 'Impossible de charger les données de parrainage.';
    }

    if (_isChinese) {
      return '无法加载推荐数据。';
    }

    if (_isVietnamese) {
      return 'Không thể tải dữ liệu giới thiệu.';
    }

    if (_isJapanese) {
      return '紹介データを読み込めませんでした。';
    }

    return 'Referral data could not be loaded.';
  }

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _functions = FirebaseFunctions.instanceFor(
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
      if (mounted) {
        setState(() {
          _refreshing = true;
          _error = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable(
        'getReferralStatus',
      );

      final HttpsCallableResult result =
          await callable.call();

      final dynamic rawData = result.data;

      if (rawData is! Map) {
        throw Exception(
          'Invalid referral response.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(rawData);

      final dynamic rawReferrals =
          data['referrals'];

      final List<_ReferralUser> loadedReferrals = [];

      if (rawReferrals is List) {
        for (final dynamic item in rawReferrals) {
          if (item is! Map) {
            continue;
          }

          loadedReferrals.add(
            _ReferralUser.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }

      final int calculatedActive =
          loadedReferrals.where(
            (user) => user.isMining,
          ).length;

      final int calculatedInactive =
          loadedReferrals.length -
              calculatedActive;

      final int loadedReferralCount = _readInt(
        data['referralCount'],
        fallback: loadedReferrals.length,
      );

      final int loadedActiveCount = _readInt(
        data['activeCount'],
        fallback: calculatedActive,
      );

      final int loadedInactiveCount = _readInt(
        data['inactiveCount'],
        fallback: calculatedInactive,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _referralCode =
            _readString(data['referralCode']);

        _referralCount =
            loadedReferralCount < 0
                ? 0
                : loadedReferralCount;

        _activeCount =
            loadedActiveCount < 0
                ? 0
                : loadedActiveCount;

        _inactiveCount =
            loadedInactiveCount < 0
                ? 0
                : loadedInactiveCount;

        _referrals = loadedReferrals;

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
        _error = error.toString();
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

    final int? parsed = int.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? fallback;
  }

  // ==========================================================
  // 🔤 SAFE STRING
  // ==========================================================

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // 📋 COPY INVITATION CODE
  // ==========================================================

  Future<void> _copyReferralCode() async {
    if (_referralCode.isEmpty) {
      return;
    }

    try {
      await Clipboard.setData(
        ClipboardData(
          text: _referralCode,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_copied),
          backgroundColor: cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_copyError),
          backgroundColor: cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
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
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(
              alpha: 0.20,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: 0.07,
              ),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.06),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.60,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🔗 INVITATION CODE CARD
  // ==========================================================

  Widget _referralCodeCard() {
    if (_referralCode.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF321B55),
            Color(0xFF1A0E31),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.34,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: pinkAccentColor.withValues(
              alpha: 0.05,
            ),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      referralBlueColor.withValues(
                        alpha: 0.18,
                      ),
                      pinkAccentColor.withValues(
                        alpha: 0.12,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: referralBlueColor.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: referralBlueColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _referralCodeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.auto_awesome_rounded,
                color: goldAccentColor,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  accentColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: referralBlueColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyReferralCode,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                  ),
                  tooltip: _copy,
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
    final bool active = user.isMining;

    final Color statusColor =
        active ? activeColor : inactiveColor;

    final String statusText =
        active ? _active : _inactive;

    final String username =
        user.username.isEmpty
            ? 'Stelluriini User'
            : user.username;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? activeColor.withValues(
                  alpha: 0.22,
                )
              : accentColor.withValues(
                  alpha: 0.16,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? activeColor.withValues(
                    alpha: 0.06,
                  )
                : accentColor.withValues(
                    alpha: 0.05,
                  ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // AVATAR
          // ======================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(
                        alpha: 0.30,
                      ),
                      pinkAccentColor.withValues(
                        alpha: 0.15,
                      ),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? activeColor.withValues(
                            alpha: 0.28,
                          )
                        : accentColor.withValues(
                            alpha: 0.24,
                          ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: pinkAccentColor.withValues(
                        alpha: 0.07,
                      ),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: pinkAccentColor,
                  size: 31,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cardColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(
                          alpha: 0.30,
                        ),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ======================================================
          // USER INFO
          // ======================================================

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
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(
                        alpha: 0.10,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ======================================================
          // REFERRAL REWARD
          // ======================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                user.referralBonus.toStringAsFixed(2),
                style: const TextStyle(
                  color: goldAccentColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'STL',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
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
        margin: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          20,
        ),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              surfaceColor,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(
              alpha: 0.14,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(
                alpha: 0.04,
              ),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(
                      alpha: 0.16,
                    ),
                    pinkAccentColor.withValues(
                      alpha: 0.08,
                    ),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _noReferrals,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.72,
                ),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 20,
      ),
      child: Column(
        children: _referrals
            .map(_referralUserCard)
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
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor,
                surfaceColor,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: pinkAccentColor.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: pinkAccentColor,
                size: 48,
              ),
              const SizedBox(height: 15),
              Text(
                _loadError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _refreshing
                    ? null
                    : () => _loadReferralStatus(
                          refresh: true,
                        ),
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: Text(_tryAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF321B55),
                    Color(0xFF21113B),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: 0.22,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: pinkAccentColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshing
                ? null
                : () => _loadReferralStatus(
                      refresh: true,
                    ),
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
            tooltip: _refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  color: accentColor,
                  backgroundColor: cardColor,
                  onRefresh: () =>
                      _loadReferralStatus(
                    refresh: true,
                  ),
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 24,
                    ),
                    children: [
                      // ==================================================
                      // COMMUNITY HEADER
                      // ==================================================

                      Container(
                        margin: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          18,
                        ),
                        padding:
                            const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF321B55),
                              Color(0xFF1A0E31),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(22),
                          border: Border.all(
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
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color:
                                  pinkAccentColor
                                      .withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // ==================================================
                            // STELLA COMMUNITY ICON
                            // ==================================================

                            Stack(
                              clipBehavior:
                                  Clip.none,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        const LinearGradient(
                                      begin:
                                          Alignment.topLeft,
                                      end: Alignment
                                          .bottomRight,
                                      colors: [
                                        accentColor,
                                        pinkAccentColor,
                                      ],
                                    ),
                                    shape:
                                        BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            accentColor
                                                .withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
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
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Icon(
                                    Icons
                                        .auto_awesome_rounded,
                                    color:
                                        goldAccentColor,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              width: 15,
                            ),

                            Expanded(
                              child: Column(
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
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.bold,
                                      letterSpacing:
                                          1.2,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    _description,
                                    style: TextStyle(
                                      color: Colors
                                          .white
                                          .withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 12,
                                      height: 1.35,
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
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            _statCard(
                              icon: Icons
                                  .people_alt_rounded,
                              value:
                                  _referralCount
                                      .toString(),
                              label:
                                  _totalInvited,
                              color: accentColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            _statCard(
                              icon: Icons
                                  .play_circle_fill_rounded,
                              value:
                                  _activeCount
                                      .toString(),
                              label: _miningNow,
                              color: activeColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            _statCard(
                              icon: Icons
                                  .pause_circle_filled_rounded,
                              value:
                                  _inactiveCount
                                      .toString(),
                              label: _notMining,
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
                      // INVITATION CODE
                      // ==================================================

                      _referralCodeCard(),

                      // ==================================================
                      // SECTION TITLE
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          18,
                          2,
                          18,
                          12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 26,
                              decoration:
                                  BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  begin:
                                      Alignment.topCenter,
                                  end: Alignment
                                      .bottomCenter,
                                  colors: [
                                    pinkAccentColor,
                                    accentColor,
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        pinkAccentColor
                                            .withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              _invitedUsers,
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            const Icon(
                              Icons.pets_rounded,
                              color:
                                  pinkAccentColor,
                              size: 17,
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
      bonus = rawBonus.toDouble();
    } else {
      bonus =
          double.tryParse(
            rawBonus.toString(),
          ) ??
          0;
    }

    if (bonus < 0) {
      bonus = 0;
    }

    final String uid =
        data['uid']?.toString() ??
            data['userId']?.toString() ??
            '';

    final String username =
        data['username']?.toString() ??
            data['displayName']?.toString() ??
            data['name']?.toString() ??
            '';

    final bool isMining =
        rawActive == true ||
        rawActive
                .toString()
                .toLowerCase() ==
            'true';

    return _ReferralUser(
      uid: uid,
      username: username,
      isMining: isMining,
      referralBonus: bonus,
    );
  }
}