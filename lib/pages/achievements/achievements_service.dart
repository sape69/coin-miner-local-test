import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementProgress {
  final String achievementId;
  final int progress;
  final int target;
  final int reward;
  final bool unlocked;
  final bool rewardClaimed;
  final DateTime? unlockedAt;
  final DateTime? rewardClaimedAt;
  final DateTime? updatedAt;

  const AchievementProgress({
    required this.achievementId,
    required this.progress,
    required this.target,
    required this.reward,
    required this.unlocked,
    required this.rewardClaimed,
    this.unlockedAt,
    this.rewardClaimedAt,
    this.updatedAt,
  });

  const AchievementProgress.empty({
    required this.achievementId,
    required this.target,
    required this.reward,
  })  : progress = 0,
        unlocked = false,
        rewardClaimed = false,
        unlockedAt = null,
        rewardClaimedAt = null,
        updatedAt = null;

  factory AchievementProgress.fromMap(
    Map<String, dynamic> map,
  ) {
    return AchievementProgress(
      achievementId:
          map['achievementId']?.toString() ?? '',
      progress: _toInt(map['progress']),
      target: _toInt(map['target']),
      reward: _toInt(map['reward']),
      unlocked: map['unlocked'] == true,
      rewardClaimed:
          map['rewardClaimed'] == true,
      unlockedAt:
          _toDateTime(map['unlockedAt']),
      rewardClaimedAt:
          _toDateTime(map['rewardClaimedAt']),
      updatedAt:
          _toDateTime(map['updatedAt']),
    );
  }

  double get progressValue {
    if (target <= 0) {
      return 0;
    }

    final double value =
        progress / target;

    if (value < 0) {
      return 0;
    }

    if (value > 1) {
      return 1;
    }

    return value;
  }

  int get safeProgress {
    if (progress < 0) {
      return 0;
    }

    if (target > 0 && progress > target) {
      return target;
    }

    return progress;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

class AchievementsService {
  static const String _region =
      'us-central1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: _region,
  );

  Future<List<AchievementProgress>>
      getAchievements() async {
    _requireUser();

    final HttpsCallable callable =
        _functions.httpsCallable(
      'getAchievements',
    );

    final HttpsCallableResult<dynamic>
        result = await callable.call();

    final dynamic data = result.data;

    if (data is! Map) {
      throw Exception(
        'Virheellinen saavutustietojen vastaus.',
      );
    }

    final dynamic achievementsData =
        data['achievements'];

    if (achievementsData is! List) {
      throw Exception(
        'Saavutustietoja ei löytynyt.',
      );
    }

    return achievementsData
        .whereType<Map>()
        .map(
          (item) =>
              AchievementProgress.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  Future<AchievementProgress?>
      getAchievement(
    String achievementId,
  ) async {
    final List<AchievementProgress>
        achievements =
        await getAchievements();

    for (final AchievementProgress achievement
        in achievements) {
      if (achievement.achievementId ==
          achievementId) {
        return achievement;
      }
    }

    return null;
  }

  Future<int> getCompletedCount() async {
    _requireUser();

    final HttpsCallable callable =
        _functions.httpsCallable(
      'getAchievementsCompleted',
    );

    final HttpsCallableResult<dynamic>
        result = await callable.call();

    final dynamic data = result.data;

    if (data is! Map) {
      throw Exception(
        'Virheellinen saavutusten määrän vastaus.',
      );
    }

    final dynamic completed =
        data['completed'];

    if (completed is int) {
      return completed;
    }

    if (completed is num) {
      return completed.toInt();
    }

    return int.tryParse(
          completed?.toString() ?? '',
        ) ??
        0;
  }

  Future<void> updateProgress({
    required String achievementId,
    required int progress,
  }) async {
    throw UnsupportedError(
      'Saavutusten eteneminen päivitetään '
      'turvallisesti palvelinpuolella.',
    );
  }

  Future<void> unlockAchievement(
    String achievementId,
  ) async {
    throw UnsupportedError(
      'Saavutusten avaaminen käsitellään '
      'palvelinpuolella.',
    );
  }

  Future<void> markRewardClaimed(
    String achievementId,
  ) async {
    throw UnsupportedError(
      'Saavutuspalkinnon lunastus käsitellään '
      'erillisellä turvallisella palvelinfunktiolla.',
    );
  }

  Future<void> initializeAchievements() async {
    await getAchievements();
  }

  void _requireUser() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Kirjautuminen vaaditaan.',
      );
    }
  }
}