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
// The notification is scheduled locally on the device, so it
// can appear even when the app is closed.
//
// Notification language is taken from the current
// Stelluriini application language.
//
// Supported languages:
//
// • fi - Suomi
// • en - English
// • de - Deutsch
// • es - Español
// • fr - Français
// • zh - 中文
// • vi - Tiếng Việt
// • ja - 日本語
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

  static const String _channelName =
      'Stelluriini Mining';

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

    // Initialize timezone database.
    //
    // We schedule notifications using a duration from "now",
    // rather than a fixed clock time.
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

    await androidPlugin?.createNotificationChannel(
      channel,
    );

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
  // The languageCode comes directly from HomePage, which means
  // the notification uses the same language selected by the
  // user in the Stelluriini application.
  //
  // Example:
  //
  //   await scheduleMiningCompletion(
  //     const Duration(hours: 24),
  //     languageCode: 'fi',
  //   );
  //
  // ============================================================

  Future<void> scheduleMiningCompletion(
    Duration remaining, {
    String? languageCode,
  }) async {
    await initialize();

    // Always remove an older mining notification first.
    await cancelMiningCompletion();

    // Do not schedule notifications for zero/negative durations.
    if (remaining <= Duration.zero) {
      return;
    }

    // ----------------------------------------------------------
    // 🌍 LANGUAGE
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
        localization.get(
      _notificationTitleKey,
    );

    final String notificationBody =
        localization.get(
      _notificationBodyKey,
    );

    // ----------------------------------------------------------
    // ⏰ SCHEDULE TIME
    // ----------------------------------------------------------

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(
      remaining,
    );

    // ----------------------------------------------------------
    // 🔔 ANDROID NOTIFICATION DETAILS
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
    // 📅 SCHEDULE
    // ----------------------------------------------------------

    await _notifications.zonedSchedule(
      _miningCompletionNotificationId,
      notificationTitle,
      notificationBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
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
          notification.id ==
          _miningCompletionNotificationId,
    );
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  void _onNotificationResponse(
    NotificationResponse response,
  ) {
    // The notification currently opens the application through
    // the normal Android notification behaviour.
    //
    // Navigation can be added here later if we want the
    // notification to open a specific Stelluriini page.
  }
}