// lib/db/app_database_stub.dart
class AppDatabase {
  static Future<AppDatabase> instance() async =>
      throw UnimplementedError('AppDatabase no disponible en esta plataforma');
  Future<void> initializeDaos() async {}
  Future<void> close() async {}
}
