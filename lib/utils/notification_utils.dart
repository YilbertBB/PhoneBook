import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/notification_handler.dart';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        if (details.payload != null && details.payload!.startsWith('update_')) {
          // ✅ USAR EL NUEVO HANDLER
          await NotificationHandler.saveNotificationPayload(details.payload!);
        }
      },
    );
  }

  static Future<void> showUpdateNotification({
    required String title,
    required String body,
    required String version,
    bool hasAction = true,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'update_channel', // ID del canal
          'Actualizaciones', // Nombre del canal
          channelDescription:
              'Notificaciones sobre actualizaciones de la aplicación',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          timeoutAfter: 86400000, // 24 horas en milisegundos
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await notificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      notificationDetails,
      payload: 'update_$version', // Payload para identificar
    );
  }

  static Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}
