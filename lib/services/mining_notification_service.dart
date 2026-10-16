import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// ============================================================
/// 🐱 STELLURIINI - MINING NOTIFICATION SERVICE
/// ============================================================
///
/// Hoitaa Stelluriini-louhinnan valmistumisilmoitukset.
///
/// Kun louhinta alkaa:
///   scheduleMiningCompleteNotification()
///
/// Kun uusi louhinta alkaa:
///   vanha ilmoitus perutaan ja uusi ajastetaan.
///
/// Kun ilmoitusta ei enää tarvita:
///   cancelMiningCompleteNotification()
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

    // Alustetaan timezone-tietokanta.
    tz.initializeTimeZones();

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
  // REQUEST NOTIFICATION PERMISSION
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
  // SCHEDULE MINING COMPLETE NOTIFICATION
  // ============================================================

  Future<void> scheduleMiningCompleteNotification({
    required Duration duration,
  }) async {
    await initialize();

    // Perutaan mahdollinen vanha ilmoitus.
    await cancelMiningCompleteNotification();

    // Jos aika on jo kulunut, ei ajasteta ilmoitusta.
    if (duration <= Duration.zero) {
      return;
    }

    final tz.TZDateTime scheduledTime =
        tz.TZDateTime.now(tz.local).add(duration);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      _miningCompleteNotificationId,
      '🐱 Stella kaipaa sinua!',
      'Louhinta on valmis. Tule käynnistämään uusi louhinta. 💜',
      scheduledTime,
      notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'mining_complete',
    );
  }

  // ============================================================
  // CANCEL MINING COMPLETE NOTIFICATION
  // ============================================================

  Future<void> cancelMiningCompleteNotification() async {
    await initialize();

    await _notifications.cancel(
      _miningCompleteNotificationId,
    );
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  Future<void> cancelAllNotifications() async {
    await initialize();

    await _notifications.cancelAll();
  }
}