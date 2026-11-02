
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../localization.dart';

// ============================================================
// 🐱 STELLURIINI - MINING NOTIFICATION SERVICE
// ============================================================
//
// Handles the local Android notification shown when the
// 24-hour Stelluriini mining session is finished.
//
// Uses exact Android alarms when permission is granted.
// Falls back to inexact scheduling when exact alarm permission
// is unavailable.
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

  static const int _miningCompletionNotificationId = 1001;

  // ------------------------------------------------------------
  // Notification channel
  // ------------------------------------------------------------

  static const String _channelId = 'stelluriini_mining';

  static const String _channelName = 'Stelluriini Mining';

  static const String _channelDescription =
      'Notification when Stelluriini mining is complete.';

  // ------------------------------------------------------------
  // Localization keys
  // ------------------------------------------------------------

  static const String _notificationTitleKey =
      'miningNotificationTitle';

  static const String _notificationBodyKey =
      'miningNotificationBody';

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

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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
  // CHECK EXACT ALARM PERMISSION
  // ============================================================

  Future<bool> canScheduleExactNotifications() async {
    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return false;
    }

    try {
      return await androidPlugin.canScheduleExactNotifications() ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REQUEST PERMISSIONS
  // ============================================================

  Future<void> requestPermission() async {
    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return;
    }

    // Request normal notification permission.
    await androidPlugin.requestNotificationsPermission();

    // Check exact alarm permission.
    bool exactAlarmGranted =
        await canScheduleExactNotifications();

    // If permission is missing, open Android's exact alarm
    // permission settings for this application.
    if (!exactAlarmGranted) {
      await androidPlugin.requestExactAlarmsPermission();

      // Check again after returning from Android settings.
      exactAlarmGranted =
          await canScheduleExactNotifications();
    }
  }

  // ============================================================
  // SCHEDULE MINING COMPLETION
  // ============================================================

  Future<void> scheduleMiningCompletion(
    Duration remaining, {
    String? languageCode,
  }) async {
    await initialize();

    // Remove an older mining completion notification.
    await cancelMiningCompletion();

    if (remaining <= Duration.zero) {
      return;
    }

    // ----------------------------------------------------------
    // LANGUAGE
    // ----------------------------------------------------------

    final String safeLanguageCode =
        AppLocalizations.normalizeLanguageCode(
      languageCode,
    );

    final AppLocalizations localization =
        AppLocalizations.forLanguage(
      safeLanguageCode,
    );

    final String notificationTitle =
        localization.get(_notificationTitleKey);

    final String notificationBody =
        localization.get(_notificationBodyKey);

    // ----------------------------------------------------------
    // SCHEDULE TIME
    // ----------------------------------------------------------

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(remaining);

    // ----------------------------------------------------------
    // ANDROID NOTIFICATION DETAILS
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // CHECK EXACT ALARM PERMISSION
    // ----------------------------------------------------------

    final bool exactAlarmGranted =
        await canScheduleExactNotifications();

    final AndroidScheduleMode scheduleMode =
        exactAlarmGranted
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

    // ----------------------------------------------------------
    // SCHEDULE NOTIFICATION
    // ----------------------------------------------------------

    await _notifications.zonedSchedule(
      _miningCompletionNotificationId,
      notificationTitle,
      notificationBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: scheduleMode,
    );

    // ----------------------------------------------------------
    // VERIFY SCHEDULE
    // ----------------------------------------------------------

    final bool scheduled =
        await hasPendingMiningCompletion();

    if (!scheduled) {
      throw Exception(
        'Mining completion notification was not scheduled.',
      );
    }
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
    // The notification opens the application normally.
  }
}
