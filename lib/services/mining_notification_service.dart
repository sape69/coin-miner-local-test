import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ============================================================
/// 🐱 STELLURIINI - MINING NOTIFICATION SERVICE
/// ============================================================
///
/// Hoitaa louhinnan valmistumisesta ilmoittamisen.
///
/// Kun louhinta alkaa:
///   → scheduleMiningCompleteNotification()
///
/// Kun uusi louhinta alkaa:
///   → vanha ilmoitus perutaan ja uusi ajastetaan.
///
/// Kun ilmoitusta ei enää tarvita:
///   → cancelMiningCompleteNotification()
///
/// ============================================================

class MiningNotificationService {
  MiningNotificationService._();

  static final MiningNotificationService instance =
      MiningNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _miningCompleteNotificationId = 1001;

  static const String _channelId = 'stelluriini_mining';
  static const String _channelName = 'Stelluriini Mining';
  static const String _channelDescription =
      'Ilmoitukset Stelluriini-louhinnan valmistumisesta.';

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      ),
    );

    _initialized = true;
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<bool> requestPermission() async {
    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return false;
    }

    final bool? granted =
        await androidPlugin.requestNotificationsPermission();

    return granted ?? false;
  }

  // ============================================================
  // SCHEDULE MINING COMPLETE
  // ============================================================

  Future<void> scheduleMiningCompleteNotification({
    required Duration duration,
  }) async {
    await initialize();

    // Varmistetaan, ettei vanha ilmoitus jää voimaan.
    await cancelMiningCompleteNotification();

    if (duration <= Duration.zero) {
      return;
    }

    final DateTime scheduledTime = DateTime.now().add(duration);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      _miningCompleteNotificationId,
      '🐱 Stella kaipaa sinua!',
      'Louhinta on valmis. Tule käynnistämään uusi louhinta. 💜',
      _convertToTzDateTime(scheduledTime),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'mining_complete',
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> cancelMiningCompleteNotification() async {
    await initialize();

    await _notifications.cancel(
      _miningCompleteNotificationId,
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAllNotifications() async {
    await initialize();

    await _notifications.cancelAll();
  }

  // ============================================================
  // TIMEZONE CONVERSION
  // ============================================================
  //
  // flutter_local_notifications käyttää tz-pakettia
  // zonedSchedule()-ajastuksessa.
  //
  // Tämän vuoksi käytetään TZDateTime.utc + paikallinen offset.
  //
  // ============================================================

  dynamic _convertToTzDateTime(DateTime dateTime) {
    // Tämä korvataan seuraavassa vaiheessa varsinaisella
    // timezone-alustuksella, kun notification-palvelu
    // yhdistetään main.dartiin.
    //
    // Jätetään tämä tarkoituksella tähän vaiheeseen, jotta
    // rakennamme notification-järjestelmän yksi tiedosto
    // kerrallaan.

    return dateTime;
  }
}