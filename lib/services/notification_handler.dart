import 'package:shared_preferences/shared_preferences.dart';

class NotificationHandler {
  static const String pendingNotificationKey = 'pending_update_notification';

  static Future<void> saveNotificationPayload(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingNotificationKey, payload);
  }

  static Future<String?> getPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(pendingNotificationKey);
  }

  static Future<void> clearPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pendingNotificationKey);
  }
}
