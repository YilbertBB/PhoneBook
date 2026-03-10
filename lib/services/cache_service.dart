import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CacheService {
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'cache'));

    Map<String, dynamic> result = {
      'total': 0,
      'items': 0,
      'details': {},
      'categories': {},
    };

    // Revisar directorio cache
    if (await cacheDir.exists()) {
      await _scanDirectory(cacheDir, 'cache', result);
    }

    // Revisar base de datos
    final dbFile = File(path.join(appDir.path, 'app_database.db'));
    if (await dbFile.exists()) {
      final stat = await dbFile.stat();
      result['total'] += stat.size;
      result['items']++;
      result['details']['app_database.db'] = stat.size;
      result['categories']['database'] =
          (result['categories']['database'] ?? 0) + stat.size;
    }

    // Revisar otros archivos comunes
    final filesToCheck = [
      'shared_preferences.json',
      'app_settings.json',
      'user_session.json',
    ];

    for (var fileName in filesToCheck) {
      final file = File(path.join(appDir.path, fileName));
      if (await file.exists()) {
        final stat = await file.stat();
        result['total'] += stat.size;
        result['items']++;
        result['details'][fileName] = stat.size;
        result['categories']['settings'] =
            (result['categories']['settings'] ?? 0) + stat.size;
      }
    }

    return result;
  }

  static Future<void> _scanDirectory(
    Directory dir,
    String category,
    Map<String, dynamic> result,
  ) async {
    try {
      final files = await dir.list(recursive: false).toList();

      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          result['total'] += stat.size;
          result['items']++;

          final relativePath = path.relative(file.path, from: dir.path);
          result['details'][relativePath] = stat.size;
          result['categories'][category] =
              (result['categories'][category] ?? 0) + stat.size;
        } else if (file is Directory) {
          await _scanDirectory(file, category, result);
        }
      }
    } catch (e) {
      debugPrint('Error escaneando directorio ${dir.path}: $e');
    }
  }

  static Future<bool> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(appDir.path, 'cache'));

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearAllData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Eliminar directorio cache
      final cacheDir = Directory(path.join(appDir.path, 'cache'));
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // Eliminar base de datos
      final dbFile = File(path.join(appDir.path, 'app_database.db'));
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
