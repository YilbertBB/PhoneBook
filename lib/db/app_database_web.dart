// lib/db/app_database_web.dart
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Future<AppDatabase> instance() async => _instance;

  Future<void> initializeDaos() async {}
  Future<void> close() async {}
}
