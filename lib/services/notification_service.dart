import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapy/core/constants/app_constants.dart';

/// Service to handle persistent navigation notifications on the lockscreen.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification system and request permissions.
  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  static String? _lastInstruction;
  static String? _lastDistance;

  /// Shows or updates a persistent navigation notification.
  static Future<void> showNavigationNotification({
    required String instruction,
    required String distance,
  }) async {
    if (instruction == _lastInstruction && distance == _lastDistance) return;
    _lastInstruction = instruction;
    _lastDistance = distance;

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
        id: AppConstants.notificationId,
        title: distance,
        body: instruction,
        notificationDetails: platformChannelSpecifics,
      );
    } catch (_) {}
  }

  /// Clears the navigation notification.
  static Future<void> cancelNavigationNotification() async {
    await _notificationsPlugin.cancel(id: AppConstants.notificationId);
  }
}
