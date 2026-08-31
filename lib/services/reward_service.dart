import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardData {
  final int stlBalance;
  final int streak;
  final int adsToday;
  final String lastDaily;
  final String adDate;
  final DateTime? lastAdTime;

  const RewardData({
    required this.stlBalance,
    required this.streak,
    required this.adsToday,
    required this.lastDaily,
    required this.adDate,
    required this.lastAdTime,
  });
}

class DailyClaimResult {
  final bool alreadyClaimed;
  final int balance;
  final int streak;
  final int reward;

  const DailyClaimResult({
    required this.alreadyClaimed,
    required this.balance,
    required this.streak,
    required this.reward,
  });
}

class AdRewardResult {
  final int balance;
  final int adsToday;
  final int reward;

  const AdRewardResult({
    required this.balance,
    required this.adsToday,
    required this.reward,
  });
}

class RewardService {
  RewardService._();

  static final RewardService instance =
      RewardService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================================
  // USER
  // ==========================================================

  String get _uid {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw StateError(
        'Käyttäjä ei ole kirjautunut.',
      );
    }

    return uid;
  }

  DocumentReference<Map<String, dynamic>>
      get _userDoc =>
          _firestore
              .collection('users')
              .doc(_uid);

  // ==========================================================
  // LOAD USER REWARD DATA
  // ==========================================================

  Future<RewardData> loadRewardData(
    String currentToday,
  ) async {
    final snapshot =
        await _userDoc.get();

    Map<String, dynamic> data;

    if (!snapshot.exists) {
      data = {
        'stlBalance': 0,
        'streak': 0,
        'lastDaily': '',
        'adsToday': 0,
        'adDate': currentToday,
      };

      await _userDoc.set(
        data,
        SetOptions(merge: true),
      );
    } else {
      data =
          snapshot.data() ??
              <String, dynamic>{};
    }

    final stlBalance =
        (data['stlBalance'] as num?)
                ?.toInt() ??
            0;

    final streak =
        (data['streak'] as num?)
                ?.toInt() ??
            0;

    int adsToday =
        (data['adsToday'] as num?)
                ?.toInt() ??
            0;

    final lastDaily =
        data['lastDaily'] as String? ?? '';

    String adDate =
        data['adDate'] as String? ?? '';

    DateTime? lastAdTime;

    final timestamp =
        data['lastAdTimestamp'];

    if (timestamp is Timestamp) {
      lastAdTime =
          timestamp.toDate();
    }

    // Vanhan version yhteensopivuus.
    final oldLastAdTime =
        data['lastAdTime'];

    if (lastAdTime == null &&
        oldLastAdTime is String &&
        oldLastAdTime.isNotEmpty) {
      lastAdTime =
          DateTime.tryParse(
        oldLastAdTime,
      );
    }

    // Uusi päivä → mainoslaskuri nollaan.
    if (adDate != currentToday) {
      adsToday = 0;
      adDate = currentToday;
    }

    return RewardData(
      stlBalance: stlBalance,
      streak: streak,
      adsToday: adsToday,
      lastDaily: lastDaily,
      adDate: adDate,
      lastAdTime: lastAdTime,
    );
  }

  // ==========================================================
  // DAILY CHECK-IN
  // ==========================================================

  Future<DailyClaimResult> claimDailyReward()
      async {
    final callable =
        _functions.httpsCallable(
      'dailyCheckIn',
    );

    final result =
        await callable.call();

    final data =
        Map<String, dynamic>.from(
      result.data as Map,
    );

    return DailyClaimResult(
      alreadyClaimed:
          data['alreadyClaimed'] == true,

      balance:
          (data['balance'] as num?)
                  ?.toInt() ??
              0,

      streak:
          (data['streak'] as num?)
                  ?.toInt() ??
              0,

      reward:
          (data['reward'] as num?)
                  ?.toInt() ??
              0,
    );
  }

  // ==========================================================
  // TEST AD REWARD
  // ==========================================================

  Future<AdRewardResult> claimTestAdReward()
      async {
    final callable =
        _functions.httpsCallable(
      'testAdReward',
    );

    final result =
        await callable.call();

    final data =
        Map<String, dynamic>.from(
      result.data as Map,
    );

    return AdRewardResult(
      balance:
          (data['balance'] as num?)
                  ?.toInt() ??
              0,

      adsToday:
          (data['adsToday'] as num?)
                  ?.toInt() ??
              0,

      reward:
          (data['reward'] as num?)
                  ?.toInt() ??
              0,
    );
  }
}