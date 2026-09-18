import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ============================================================
// 🐱 STELLURIINI REWARD DATA
// ============================================================
//
// Tämä data vastaa nykyistä Stelluriinin mining-mallia.
//
// Daily Check-In ei lisää STL-saldoa.
// Daily Check-In vaikuttaa käyttäjän Hash Rateen
// ja Daily Streakiin.
//
// ============================================================

class RewardData {
  final double hashRate;
  final int dailyStreak;
  final String lastDailyDate;
  final int adsToday;
  final String adDate;
  final DateTime? lastAdTime;

  const RewardData({
    required this.hashRate,
    required this.dailyStreak,
    required this.lastDailyDate,
    required this.adsToday,
    required this.adDate,
    required this.lastAdTime,
  });
}


// ============================================================
// 🎁 DAILY CLAIM RESULT
// ============================================================
//
// Vastaa functions/src/functions/daily.js palautetta.
//
// Esimerkki:
//
// {
//   success: true,
//   claimed: true,
//   alreadyClaimed: false,
//   dailyClaimed: true,
//   date: "2026-09-18",
//   bonus: 2.0,
//   dailyHashRate: 2.0,
//   hashRate: 2.0,
//   streak: 4,
//   dailyStreak: 4,
// }
//
// ============================================================

class DailyClaimResult {
  final bool success;
  final bool claimed;
  final bool alreadyClaimed;
  final bool dailyClaimed;

  final String date;

  final double bonus;
  final double dailyHashRate;
  final double hashRate;

  final int streak;
  final int dailyStreak;

  final String message;

  const DailyClaimResult({
    required this.success,
    required this.claimed,
    required this.alreadyClaimed,
    required this.dailyClaimed,
    required this.date,
    required this.bonus,
    required this.dailyHashRate,
    required this.hashRate,
    required this.streak,
    required this.dailyStreak,
    required this.message,
  });
}


// ============================================================
// 🐱 REWARD SERVICE
// ============================================================
//
// Vastaa:
//
// 📅 Daily Check-Inin kutsumisesta
// 📊 Reward/mining-tietojen lukemisesta
//
// Tämä service EI:
//
// ❌ lisää STL-saldoa
// ❌ käsittele AdMob SSV:tä
// ❌ aktivoi Power Boostia
// ❌ käsittele Mining Startia
// ❌ validoi AdMob transaction_id:tä
//
// AdMob SSV käsitellään Cloud Functions -puolella.
//
// ============================================================

class RewardService {
  RewardService._();

  static final RewardService instance =
      RewardService._();


  // ==========================================================
  // 🔥 FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;


  // ==========================================================
  // 👤 USER UID
  // ==========================================================

  String get _uid {
    final uid =
        _auth.currentUser?.uid;

    if (uid == null ||
        uid.isEmpty) {
      throw StateError(
        'Käyttäjä ei ole kirjautunut.',
      );
    }

    return uid;
  }


  // ==========================================================
  // 👤 USER DOCUMENT
  // ==========================================================

  DocumentReference<Map<String, dynamic>>
      get _userDoc =>
          _firestore
              .collection('users')
              .doc(_uid);


  // ==========================================================
  // 📊 LOAD REWARD / MINING DATA
  // ==========================================================
  //
  // currentToday annetaan UI:n nykyisen päivän perusteella.
  //
  // Esimerkiksi:
  //
  // 2026-09-18
  //
  // Jos adDate on vanha, adsToday palautetaan nollana
  // paikallista käyttöliittymää varten.
  //
  // Varsinainen mainosrajoitus tulee aina toteuttaa
  // Cloud Functions -puolella.
  //
  // ==========================================================

  Future<RewardData> loadRewardData(
    String currentToday,
  ) async {
    final snapshot =
        await _userDoc.get();

    Map<String, dynamic> data;

    if (!snapshot.exists) {
      data = {
        'hashRate': 0.0,
        'dailyStreak': 0,
        'lastDailyDate': '',
        'adsToday': 0,
        'adDate': currentToday,
      };

      await _userDoc.set(
        data,
        SetOptions(
          merge: true,
        ),
      );
    } else {
      data =
          snapshot.data() ??
              <String, dynamic>{};
    }


    // ========================================================
    // ⚡ HASH RATE
    // ========================================================

    final hashRate =
        _readDouble(
          data['hashRate'],
        );


    // ========================================================
    // 🔥 DAILY STREAK
    // ========================================================

    final dailyStreak =
        _readInt(
          data['dailyStreak'],
        );


    // ========================================================
    // 📅 LAST DAILY DATE
    // ========================================================

    final lastDailyDate =
        data['lastDailyDate']
                is String
            ? data['lastDailyDate']
                as String
            : '';


    // ========================================================
    // 📺 ADS TODAY
    // ========================================================

    int adsToday =
        _readInt(
          data['adsToday'],
        );


    // ========================================================
    // 📅 AD DATE
    // ========================================================

    String adDate =
        data['adDate'] is String
            ? data['adDate'] as String
            : '';


    // ========================================================
    // ⏱️ LAST AD TIME
    // ========================================================

    DateTime? lastAdTime;


    final timestamp =
        data['lastAdTimestamp'];


    if (timestamp is Timestamp) {
      lastAdTime =
          timestamp.toDate();
    }


    // ========================================================
    // 🔄 OLD VERSION COMPATIBILITY
    // ========================================================
    //
    // Vanha järjestelmä käytti:
    //
    // lastAdTime: String
    //
    // Tätä voidaan lukea vanhoista käyttäjädokumenteista,
    // mutta uutta arvoa ei kirjoiteta tällä tavalla.
    //
    // ========================================================

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


    // ========================================================
    // 📅 NEW DAY
    // ========================================================
    //
    // Käyttöliittymän paikallinen laskuri nollataan uuden
    // päivän kohdalla.
    //
    // Tämä EI ole turvallisuusrajoitus.
    //
    // Cloud Functions päättää aina oikean adsToday-arvon.
    //
    // ========================================================

    if (adDate != currentToday) {
      adsToday = 0;
      adDate = currentToday;
    }


    // ========================================================
    // 📦 RETURN
    // ========================================================

    return RewardData(
      hashRate: hashRate,
      dailyStreak: dailyStreak,
      lastDailyDate: lastDailyDate,
      adsToday: adsToday,
      adDate: adDate,
      lastAdTime: lastAdTime,
    );
  }


  // ==========================================================
  // 📅 DAILY CHECK-IN
  // ==========================================================
  //
  // Kutsuu:
  //
  // functions/src/functions/daily.js
  //
  // Cloud Function vastaa:
  //
  // - Daily Streakistä
  // - Daily Hash Ratesta
  // - duplicate-claimin estosta
  // - Firestore transactionista
  // - Daily Historystä
  // - Achievements-päivityksistä
  //
  // ==========================================================

  Future<DailyClaimResult>
      claimDailyReward() async {
    final callable =
        _functions.httpsCallable(
      'dailyCheckIn',
    );


    final result =
        await callable.call();


    if (result.data is! Map) {
      throw StateError(
        'dailyCheckIn palautti virheellisen vastauksen.',
      );
    }


    final data =
        Map<String, dynamic>.from(
      result.data as Map,
    );


    // ========================================================
    // 📊 READ RESPONSE
    // ========================================================

    return DailyClaimResult(
      success:
          data['success'] == true,

      claimed:
          data['claimed'] == true,

      alreadyClaimed:
          data['alreadyClaimed'] == true,

      dailyClaimed:
          data['dailyClaimed'] == true,

      date:
          data['date'] is String
              ? data['date'] as String
              : '',

      bonus:
          _readDouble(
        data['bonus'],
      ),

      dailyHashRate:
          _readDouble(
        data['dailyHashRate'],
      ),

      hashRate:
          _readDouble(
        data['hashRate'],
      ),

      streak:
          _readInt(
        data['streak'],
      ),

      dailyStreak:
          _readInt(
        data['dailyStreak'],
      ),

      message:
          data['message'] is String
              ? data['message'] as String
              : '',
    );
  }


  // ==========================================================
  // 🔢 READ INTEGER
  // ==========================================================

  static int _readInt(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }


  // ==========================================================
  // ⚡ READ DOUBLE
  // ==========================================================

  static double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value,
          ) ??
          0.0;
    }

    return 0.0;
  }
}