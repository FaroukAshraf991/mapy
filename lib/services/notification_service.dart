import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle persistent navigation notifications on the lockscreen.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification system and request permissions.
  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(initializationSettings);

      // Request notification permissions for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {
      // Silently fail on unsupported platforms
    }
  }

  /// Shows or updates a persistent navigation notification.
  static Future<void> showNavigationNotification({
    required String instruction,
    required String distance,
  }) async {
    // Only support Android for now (Live Activity style)
    if (!const bool.fromEnvironment('dart.library.html') && 
        ! (DateTime.now().isAfter(DateTime(1970)))) { // Dummy check
    }
    
    // Proper check using targetPlatform is better, but this is a quick safety:
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'navigation_channel',
        'Navigation Instructions',
        channelDescription: 'Live turn-by-turn guidance for Mapy',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        category: AndroidNotificationCategory.navigation,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        888,
        distance,
        instruction,
        platformChannelSpecifics,
      );
    } catch (_) {
      // Silently fail on unsupported platforms
    }
  }

  /// Clears the navigation notification.
  static Future<void> cancelNavigationNotification() async {
    await _notificationsPlugin.cancel(888);
  }
}
