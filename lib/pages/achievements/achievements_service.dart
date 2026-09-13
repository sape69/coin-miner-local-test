import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'achievement_model.dart';

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENTS SERVICE
// ============================================================
//
// Flutter-sovellus käyttää tätä palvelua saavutusten LUKEMISEEN.
//
// TÄRKEÄ TURVALLISUUSMALLI:
//
// Flutter EI kirjoita achievements-dokumentteihin.
//
// Saavutusten:
// - progress
// - unlock
// - reward
// - rewardClaimed
//
// käsittely tapahtuu Cloud Functions -puolella.
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

  User? get _currentUser {
    return _auth.currentUser;
  }

  String? get _userId {
    return _currentUser?.uid;
  }

  // ============================================================
  // 📁 ACHIEVEMENTS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>?
      get _achievementsCollection {
    final String? userId = _userId;

    if (userId == null || userId.isEmpty) {
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
  //
  // Flutter saa lukea omat saavutuksensa.
  //
  // Kirjoituksia ei tehdä tässä metodissa.
  //
  // ============================================================

  Future<Map<String, AchievementProgress>>
      getAchievements() async {
    final CollectionReference<Map<String, dynamic>>?
        collection = _achievementsCollection;

    if (collection == null) {
      return {};
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await collection.get();

    final Map<String, AchievementProgress> result =
        <String, AchievementProgress>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        document in snapshot.docs) {
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

  Future<AchievementProgress> getAchievement(
    Achievement achievement,
  ) async {
    final CollectionReference<Map<String, dynamic>>?
        collection = _achievementsCollection;

    if (collection == null) {
      return AchievementProgress.empty(
        achievement.id,
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await collection
            .doc(achievement.id)
            .get();

    if (!document.exists || document.data() == null) {
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
  // 🔄 INITIALIZE
  // ============================================================
  //
  // Achievementit luodaan nykyisessä arkkitehtuurissa
  // Cloud Functions -puolella.
  //
  // Tätä metodia ei poisteta, koska AchievementsPage voi
  // edelleen kutsua sitä.
  //
  // Se ei kuitenkaan tee mitään asiakaspuolella.
  //
  // Tämä estää Flutteria kirjoittamasta Firestoreen.
  //
  // ============================================================

  Future<void> initializeAchievements() async {
    // Ei asiakaspuolen Firestore-kirjoituksia.
    //
    // Cloud Functions luo ja päivittää achievementit
    // tarvittaessa.
    return;
  }

  // ============================================================
  // 📊 GET COMPLETED COUNT
  // ============================================================

  Future<int> getCompletedCount() async {
    final Map<String, AchievementProgress> achievements =
        await getAchievements();

    return achievements.values
        .where(
          (AchievementProgress achievement) =>
              achievement.unlocked,
        )
        .length;
  }

  // ============================================================
  // 📋 GET ALL DEFINED ACHIEVEMENTS WITH PROGRESS
  // ============================================================
  //
  // Tämä on käyttöliittymälle hyödyllinen apumetodi.
  //
  // Firestoresta löytyvät achievementit yhdistetään
  // StelluriiniAchievements.all-listaan.
  //
  // Jos jotakin achievementia ei vielä ole Firestoressa,
  // käyttöliittymä saa sille turvallisen tyhjän arvon.
  //
  // Näin uusi käyttäjä voi avata Achievements-sivun
  // vaikka yksikään achievement ei olisi vielä aktivoitunut.
  //
  // ============================================================

  Future<Map<String, AchievementProgress>>
      getAllWithDefaults() async {
    final Map<String, AchievementProgress> existing =
        await getAchievements();

    final Map<String, AchievementProgress> result =
        <String, AchievementProgress>{};

    for (final Achievement achievement
        in StelluriiniAchievements.all) {
      result[achievement.id] =
          existing[achievement.id] ??
              AchievementProgress.fromAchievement(
                achievement,
              );
    }

    return result;
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
  // 🆕 CREATE FROM ACHIEVEMENT DEFINITION
  // ============================================================
  //
  // Käytetään silloin, kun achievement-dokumenttia ei vielä
  // ole Firestoressa.
  //
  // ============================================================

  factory AchievementProgress.fromAchievement(
    Achievement achievement,
  ) {
    return AchievementProgress(
      achievementId: achievement.id,
      progress: 0,
      target: achievement.target,
      reward: achievement.reward,
      unlocked: false,
      rewardClaimed: false,
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  factory AchievementProgress.empty(
    String achievementId,
  ) {
    return AchievementProgress(
      achievementId: achievementId,
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
      achievementId: achievementId,
      progress: _readInt(
        data['progress'],
      ),
      target: _readInt(
        data['target'],
      ),
      reward: _readInt(
        data['reward'],
      ),
      unlocked: data['unlocked'] == true,
      rewardClaimed: data['rewardClaimed'] == true,
      unlockedAt: _readDateTime(
        data['unlockedAt'],
      ),
      rewardClaimedAt: _readDateTime(
        data['rewardClaimedAt'],
      ),
      updatedAt: _readDateTime(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // 🔢 READ INTEGER
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

  // ============================================================
  // 🕒 READ DATETIME
  // ============================================================

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
  // 📈 PROGRESS VALUE
  // ============================================================

  double get progressValue {
    if (unlocked) {
      return 1.0;
    }

    if (target <= 0) {
      return 0.0;
    }

    return (progress / target).clamp(
      0.0,
      1.0,
    );
  }

  // ============================================================
  // 📊 DISPLAY PROGRESS
  // ============================================================

  int get safeProgress {
    if (progress < 0) {
      return 0;
    }

    if (target > 0 && progress > target) {
      return target;
    }

    return progress;
  }
}