import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/update_info.dart';
import '../../utils/update_config.dart';

class UpdateRepository {
  final http.Client client;

  UpdateRepository({http.Client? client}) : client = client ?? http.Client();

  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await client.get(
        Uri.parse(UpdateConfig.updateJsonUrl),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UpdateInfo.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      UpdateConfig.lastCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(UpdateConfig.lastCheckKey);
    if (lastCheck != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastCheck);
    }
    return null;
  }

  Future<bool> shouldCheckForUpdates() async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) {
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(lastCheck);
    return difference.inHours >= UpdateConfig.checkIntervalHours;
  }

  // AGREGAR este método para verificar si ya se mostró hoy
  Future<bool> _hasShownUpdateToday(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'shown_update_${version}_date';
    final lastShownDate = prefs.getString(key);

    if (lastShownDate == null) return false;

    final today = DateTime.now();
    final lastShown = DateTime.parse(lastShownDate);

    // Si ya se mostró hoy, no mostrar de nuevo
    return today.year == lastShown.year &&
        today.month == lastShown.month &&
        today.day == lastShown.day;
  }

  // MODIFICAR el método saveIgnoredUpdate para incluir fecha
  Future<void> saveIgnoredUpdate(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UpdateConfig.ignoredUpdateKey, version);

    // También guardar la fecha de hoy para no mostrar hasta mañana
    final today = DateTime.now().toIso8601String();
    await prefs.setString('shown_update_${version}_date', today);
  }

  // AGREGAR método para verificar si debe mostrar la notificación
  Future<bool> shouldShowUpdateNotification(UpdateInfo updateInfo) async {
    // Verificar si el usuario ignoró esta versión específica
    final ignoredVersion = await getIgnoredUpdate();
    if (ignoredVersion == updateInfo.latestVersion) {
      // Verificar si ya se mostró hoy
      return !(await _hasShownUpdateToday(updateInfo.latestVersion));
    }
    return true;
  }

  Future<String?> getIgnoredUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(UpdateConfig.ignoredUpdateKey);
  }

  Future<void> clearIgnoredUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UpdateConfig.ignoredUpdateKey);
  }

  // En UpdateRepository
  Future<void> clearIgnoredUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UpdateConfig.ignoredUpdateKey);
  }

  void dispose() {
    client.close();
  }
}
