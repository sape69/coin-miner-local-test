import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ============================================================
// 🐱 STELLURIINI - MINING NOTIFICATION SERVICE
// ============================================================
//
// Handles the local Android notification shown when the
// 24-hour Stelluriini mining session is finished.
//
// The notification is scheduled locally on the device, so it
// can appear even when the app is closed.
//
// ============================================================

class MiningNotificationService {
  MiningNotificationService._();

  static final MiningNotificationService instance =
      MiningNotificationService._();

  // ------------------------------------------------------------
  // Notification plugin
  // ------------------------------------------------------------

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ------------------------------------------------------------
  // Notification ID
  // ------------------------------------------------------------

  // One fixed ID is used so a new mining session replaces the
  // previous scheduled mining-completion notification.
  static const int _miningCompletionNotificationId = 1001;

  // ------------------------------------------------------------
  // Notification channel
  // ------------------------------------------------------------

  static const String _channelId = 'stelluriini_mining';
  static const String _channelName = 'Stelluriini louhinta';
  static const String _channelDescription =
      'Ilmoitus, kun Stelluriini-louhinta on valmis.';

  // ------------------------------------------------------------
  // Notification text
  // ------------------------------------------------------------

  static const String _notificationTitle =
      '🐱 Stella kaipaa sinua louhimaan!';

  static const String _notificationBody =
      'Louhinta on valmis. Tule käynnistämään uusi louhinta. 💜';

  // ------------------------------------------------------------
  // Initialization state
  // ------------------------------------------------------------

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Initialize timezone database.
    //
    // We schedule notifications using a duration from "now",
    // rather than a fixed clock time, so the device's actual
    // timezone does not need to be manually selected here.
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create the Android notification channel.
    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<void> requestPermission() async {
    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ============================================================
  // SCHEDULE MINING COMPLETION
  // ============================================================
  //
  // Schedules the notification after the supplied duration.
  //
  // Example:
  //
  //   scheduleMiningCompletion(
  //     const Duration(hours: 24),
  //   );
  //
  // The existing notification is cancelled first so that
  // multiple mining sessions cannot create duplicate alerts.
  // ============================================================

  Future<void> scheduleMiningCompletion(Duration remaining) async {
    await initialize();

    // Always remove an older mining notification first.
    await cancelMiningCompletion();

    // Do not schedule notifications for zero/negative durations.
    if (remaining <= Duration.zero) {
      return;
    }

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(remaining);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      _miningCompletionNotificationId,
      _notificationTitle,
      _notificationBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ============================================================
  // CANCEL MINING COMPLETION
  // ============================================================

  Future<void> cancelMiningCompletion() async {
    await _notifications.cancel(
      _miningCompletionNotificationId,
    );
  }

  // ============================================================
  // CHECK PENDING NOTIFICATION
  // ============================================================

  Future<bool> hasPendingMiningCompletion() async {
    await initialize();

    final List<PendingNotificationRequest> pending =
        await _notifications.pendingNotificationRequests();

    return pending.any(
      (PendingNotificationRequest notification) =>
          notification.id == _miningCompletionNotificationId,
    );
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  void _onNotificationResponse(
    NotificationResponse response,
  ) {
    // The notification currently only needs to open the app
    // through the normal Android notification behaviour.
    //
    // Navigation can be added here later if we want the
    // notification to open a specific Stelluriini page.
  }
}