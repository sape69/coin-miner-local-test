import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserData {
  final int stlBalance;
  final int streak;
  final String lastDaily;
  final int adsToday;
  final String adDate;
  final DateTime? lastAdTime;

  const UserData({
    required this.stlBalance,
    required this.streak,
    required this.lastDaily,
    required this.adsToday,
    required this.adDate,
    required this.lastAdTime,
  });

  factory UserData.empty() {
    return const UserData(
      stlBalance: 0,
      streak: 0,
      lastDaily: '',
      adsToday: 0,
      adDate: '',
      lastAdTime: null,
    );
  }

  factory UserData.fromMap(Map<String, dynamic> data) {
    DateTime? lastAdTime;

    final timestamp = data['lastAdTime'];

    if (timestamp is Timestamp) {
      lastAdTime = timestamp.toDate();
    }

    return UserData(
      stlBalance: (data['stlBalance'] ?? 0) as int,
      streak: (data['streak'] ?? 0) as int,
      lastDaily: (data['lastDaily'] ?? '') as String,
      adsToday: (data['adsToday'] ?? 0) as int,
      adDate: (data['adDate'] ?? '') as String,
      lastAdTime: lastAdTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stlBalance': stlBalance,
      'streak': streak,
      'lastDaily': lastDaily,
      'adsToday': adsToday,
      'adDate': adDate,
      'lastAdTime': lastAdTime == null
          ? null
          : Timestamp.fromDate(lastAdTime!),
    };
  }

  UserData copyWith({
    int? stlBalance,
    int? streak,
    String? lastDaily,
    int? adsToday,
    String? adDate,
    DateTime? lastAdTime,
    bool clearLastAdTime = false,
  }) {
    return UserData(
      stlBalance: stlBalance ?? this.stlBalance,
      streak: streak ?? this.streak,
      lastDaily: lastDaily ?? this.lastDaily,
      adsToday: adsToday ?? this.adsToday,
      adDate: adDate ?? this.adDate,
      lastAdTime: clearLastAdTime
          ? null
          : lastAdTime ?? this.lastAdTime,
    );
  }
}

class UserService {
  UserService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static String? get _uid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static DocumentReference<Map<String, dynamic>>?
      get _userDocument {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    return _firestore.collection('users').doc(uid);
  }

  // ==========================================================
  // CREATE USER
  // ==========================================================

  static Future<void> createUserIfNeeded() async {
    final document = _userDocument;

    if (document == null) {
      return;
    }

    final snapshot = await document.get();

    if (snapshot.exists) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    final data = UserData.empty();

    await document.set({
      ...data.toMap(),
      'email': user?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // LOAD USER DATA
  // ==========================================================

  static Future<UserData> loadUserData() async {
    final document = _userDocument;

    if (document == null) {
      return UserData.empty();
    }

    await createUserIfNeeded();

    final snapshot = await document.get();

    final data = snapshot.data();

    if (data == null) {
      return UserData.empty();
    }

    return UserData.fromMap(data);
  }

  // ==========================================================
  // SAVE ALL DATA
  // ==========================================================

  static Future<void> saveUserData(
    UserData userData,
  ) async {
    final document = _userDocument;

    if (document == null) {
      return;
    }

    await document.set(
      userData.toMap(),
      SetOptions(merge: true),
    );
  }

  // ==========================================================
  // SAVE DAILY REWARD
  // ==========================================================

  static Future<void> saveDailyReward({
    required int stlBalance,
    required int streak,
    required String lastDaily,
  }) async {
    final document = _userDocument;

    if (document == null) {
      return;
    }

    await document.set(
      {
        'stlBalance': stlBalance,
        'streak': streak,
        'lastDaily': lastDaily,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ==========================================================
  // SAVE AD REWARD
  // ==========================================================

  static Future<void> saveAdReward({
    required int stlBalance,
    required int adsToday,
    required String adDate,
    required DateTime lastAdTime,
  }) async {
    final document = _userDocument;

    if (document == null) {
      return;
    }

    await document.set(
      {
        'stlBalance': stlBalance,
        'adsToday': adsToday,
        'adDate': adDate,
        'lastAdTime':
            Timestamp.fromDate(lastAdTime),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ==========================================================
  // UPDATE EMAIL
  // ==========================================================

  static Future<void> updateEmail() async {
    final document = _userDocument;
    final user = FirebaseAuth.instance.currentUser;

    if (document == null || user == null) {
      return;
    }

    await document.set(
      {
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}