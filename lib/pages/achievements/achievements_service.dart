import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'achievement_model.dart';

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENTS SERVICE
// ============================================================
//
// Vastaa:
// - käyttäjän saavutusten lukemisesta
// - saavutuksen avaamisesta
// - saavutuksen etenemisestä
// - palkintojen käsittelystä
//
// Firestore:
// users/{userId}/achievements/{achievementId}
//
// ============================================================

class AchievementsService {
  AchievementsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // 👤 CURRENT USER
  // ============================================================

  User? get _currentUser =>
      _auth.currentUser;

  String? get _userId =>
      _currentUser?.uid;

  // ============================================================
  // 📁 ACHIEVEMENTS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>?
      get _achievementsCollection {
    final String? userId = _userId;

    if (userId == null ||
        userId.isEmpty) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements');
  }

  // ============================================================
  // 📖 GET ALL USER ACHIEVEMENTS
  // ============================================================

  Future<Map<String, AchievementProgress>>
      getAchievements() async {
    final CollectionReference<
            Map<String, dynamic>>?
        collection =
        _achievementsCollection;

    if (collection == null) {
      return {};
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await collection.get();

    final Map<String, AchievementProgress>
        result = {};

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document
        in snapshot.docs) {
      result[document.id] =
          AchievementProgress.fromMap(
        document.id,
        document.data(),
      );
    }

    return result;
  }

  // ============================================================
  // 📖 GET ONE ACHIEVEMENT
  // ============================================================

  Future<AchievementProgress>
      getAchievement(
    Achievement achievement,
  ) async {
    final CollectionReference<
            Map<String, dynamic>>?
        collection =
        _achievementsCollection;

    if (collection == null) {
      return AchievementProgress.empty(
        achievement.id,
      );
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        document =
        await collection
            .doc(achievement.id)
            .get();

    if (!document.exists ||
        document.data() == null) {
      return AchievementProgress.empty(
        achievement.id,
      );
    }

    return AchievementProgress.fromMap(
      document.id,
      document.data()!,
    );
  }

  // ============================================================
  // 📈 UPDATE PROGRESS
  // ============================================================
  //
  // Tämä päivittää saavutuksen etenemisen.
  //
  // Jos target saavutetaan:
  // - achievement merkitään avatuksi
  // - reward merkitään lunastettavaksi
  //
  // Palkintoa EI vielä lisätä saldoon tässä vaiheessa.
  // Se tehdään erillisellä turvallisella toiminnolla.
  //
  // ============================================================

  Future<AchievementProgress>
      updateProgress({
    required Achievement achievement,
    required int progress,
  }) async {
    final CollectionReference<
            Map<String, dynamic>>?
        collection =
        _achievementsCollection;

    if (collection == null) {
      return AchievementProgress.empty(
        achievement.id,
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        document =
        collection.doc(
      achievement.id,
    );

    final int safeProgress =
        progress.clamp(
      0,
      achievement.target,
    );

    final bool unlocked =
        safeProgress >=
            achievement.target;

    final DocumentSnapshot<
            Map<String, dynamic>>
        existing =
        await document.get();

    final Map<String, dynamic>
        data =
        existing.data() ??
            <String, dynamic>{};

    final bool alreadyUnlocked =
        data['unlocked'] == true;

    final bool rewardClaimed =
        data['rewardClaimed'] == true;

    final Timestamp now =
        Timestamp.now();

    await document.set(
      <String, dynamic>{
        'achievementId':
            achievement.id,
        'progress':
            safeProgress,
        'target':
            achievement.target,
        'reward':
            achievement.reward,
        'unlocked':
            alreadyUnlocked || unlocked,
        'rewardClaimed':
            rewardClaimed,
        if (unlocked &&
            !alreadyUnlocked)
          'unlockedAt':
              now,
        'updatedAt':
            now,
      },
      SetOptions(
        merge: true,
      ),
    );

    return getAchievement(
      achievement,
    );
  }

  // ============================================================
  // 🏆 UNLOCK ACHIEVEMENT
  // ============================================================

  Future<AchievementProgress>
      unlockAchievement(
    Achievement achievement,
  ) async {
    return updateProgress(
      achievement: achievement,
      progress: achievement.target,
    );
  }

  // ============================================================
  // 🎁 MARK REWARD AS CLAIMED
  // ============================================================
  //
  // Tämä vain merkitsee palkinnon lunastetuksi.
  //
  // Varsinainen STL-saldon muuttaminen kannattaa tehdä
  // Cloud Functions -puolella, jotta käyttäjä ei voi
  // manipuloida saldoa suoraan sovelluksesta.
  //
  // ============================================================

  Future<bool> markRewardClaimed(
    Achievement achievement,
  ) async {
    final CollectionReference<
            Map<String, dynamic>>?
        collection =
        _achievementsCollection;

    if (collection == null) {
      return false;
    }

    final DocumentReference<
            Map<String, dynamic>>
        document =
        collection.doc(
      achievement.id,
    );

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await document.get();

    final Map<String, dynamic>?
        data =
        snapshot.data();

    if (data == null) {
      return false;
    }

    if (data['unlocked'] != true) {
      return false;
    }

    if (data['rewardClaimed'] == true) {
      return false;
    }

    await document.set(
      <String, dynamic>{
        'rewardClaimed':
            true,
        'rewardClaimedAt':
            Timestamp.now(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return true;
  }

  // ============================================================
  // 🔄 INITIALIZE MISSING ACHIEVEMENTS
  // ============================================================
  //
  // Luo Firestoreen puuttuvat saavutukset.
  // Olemassa olevia tietoja ei ylikirjoiteta.
  //
  // ============================================================

  Future<void>
      initializeAchievements() async {
    final CollectionReference<
            Map<String, dynamic>>?
        collection =
        _achievementsCollection;

    if (collection == null) {
      return;
    }

    final WriteBatch batch =
        _firestore.batch();

    final Map<String, AchievementProgress>
        existing =
        await getAchievements();

    for (final Achievement achievement
        in StelluriiniAchievements.all) {
      if (existing.containsKey(
        achievement.id,
      )) {
        continue;
      }

      final DocumentReference<
              Map<String, dynamic>>
          document =
          collection.doc(
        achievement.id,
      );

      batch.set(
        document,
        <String, dynamic>{
          'achievementId':
              achievement.id,
          'progress':
              0,
          'target':
              achievement.target,
          'reward':
              achievement.reward,
          'unlocked':
              false,
          'rewardClaimed':
              false,
          'updatedAt':
              Timestamp.now(),
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // 📊 GET COMPLETED COUNT
  // ============================================================

  Future<int> getCompletedCount()
      async {
    final Map<String, AchievementProgress>
        achievements =
        await getAchievements();

    return achievements.values
        .where(
          (AchievementProgress achievement) =>
              achievement.unlocked,
        )
        .length;
  }
}

// ============================================================
// 📊 ACHIEVEMENT PROGRESS
// ============================================================

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

  // ============================================================
  // EMPTY
  // ============================================================

  factory AchievementProgress.empty(
    String achievementId,
  ) {
    return AchievementProgress(
      achievementId:
          achievementId,
      progress: 0,
      target: 0,
      reward: 0,
      unlocked: false,
      rewardClaimed: false,
    );
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory AchievementProgress.fromMap(
    String achievementId,
    Map<String, dynamic> data,
  ) {
    return AchievementProgress(
      achievementId:
          achievementId,
      progress:
          _readInt(
        data['progress'],
      ),
      target:
          _readInt(
        data['target'],
      ),
      reward:
          _readInt(
        data['reward'],
      ),
      unlocked:
          data['unlocked'] == true,
      rewardClaimed:
          data['rewardClaimed'] == true,
      unlockedAt:
          _readDateTime(
        data['unlockedAt'],
      ),
      rewardClaimedAt:
          _readDateTime(
        data['rewardClaimedAt'],
      ),
      updatedAt:
          _readDateTime(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // PROGRESS VALUE
  // ============================================================

  double get progressValue {
    if (unlocked) {
      return 1.0;
    }

    if (target <= 0) {
      return 0.0;
    }

    return (progress / target)
        .clamp(0.0, 1.0);
  }

  // ============================================================
  // DISPLAY PROGRESS
  // ============================================================

  int get safeProgress {
    if (progress < 0) {
      return 0;
    }

    if (target > 0 &&
        progress > target) {
      return target;
    }

    return progress;
  }
}