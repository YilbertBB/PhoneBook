import 'package:sqflite/sqflite.dart';
import '../../models/rol.dart';
import '../entities/user_entity.dart';
import '../../../../models/user.dart';

class UserDao {
  final Database database;

  UserDao(this.database);

  static const String usersTable = 'users';
  static const String sessionsTable = 'sessions';

  // Crear tablas
  static Future<void> createTables(Database db) async {
    // Tabla de usuarios (solo lectura para cache)
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        display_role TEXT NOT NULL,
        is_admin INTEGER NOT NULL DEFAULT 0,
        last_synced_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id) ON CONFLICT REPLACE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_username 
      ON $usersTable (username)
    ''');

    // Tabla de sesiones (para auth)
    await db.execute('''
      CREATE TABLE $sessionsTable (
        user_id INTEGER PRIMARY KEY,
        token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        logged_in_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== OPERACIONES DE USUARIOS ==========

  Future<int> insertOrUpdateUser(UserEntity user) async {
    return await database.insert(
      usersTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrUpdateUsers(List<UserEntity> users) async {
    final batch = database.batch();
    for (final user in users) {
      batch.insert(
        usersTable,
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<UserEntity>> getAllUsers() async {
    final List<Map<String, dynamic>> maps = await database.query(
      usersTable,
      orderBy: 'username ASC',
    );
    return maps.map((map) => UserEntity.fromMap(map)).toList();
  }

  Future<UserEntity?> getUserById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserEntity.fromMap(maps.first);
  }

  Future<List<UserEntity>> searchUsers(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await database.query(
      usersTable,
      where: 'username LIKE ? OR email LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      orderBy: 'username ASC',
    );
    return maps.map((map) => UserEntity.fromMap(map)).toList();
  }

  // Convertir a modelo User
  User toUserModel(UserEntity entity) {
    return User(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      password: '', // No guardamos contraseñas localmente
      roles: [
        entity.isAdmin
            ? Rol(id: 1, nombre: 'admin')
            : Rol(id: 2, nombre: 'consult'),
      ],
      createdAt: DateTime.now(),
    );
  }

  List<User> toUserModelList(List<UserEntity> entities) {
    return entities.map(toUserModel).toList();
  }

  Future<int> countUsers() async {
    final result = await database.rawQuery('SELECT COUNT(*) FROM $usersTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== OPERACIONES DE SESIÓN ==========

  Future<void> saveSession(SessionEntity session) async {
    await database.insert(
      sessionsTable,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SessionEntity?> getSession() async {
    final List<Map<String, dynamic>> maps = await database.query(
      sessionsTable,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SessionEntity.fromMap(maps.first);
  }

  Future<void> clearSession() async {
    await database.delete(sessionsTable);
  }

  Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null && session.isValid;
  }

  // ========== OPERACIONES DE SINCRONIZACIÓN ==========

  Future<DateTime?> getLastSyncDate() async {
    final result = await database.rawQuery(
      'SELECT MAX(last_synced_at) FROM $usersTable WHERE is_synced = 1',
    );
    final maxTimestamp = Sqflite.firstIntValue(result);
    if (maxTimestamp == null || maxTimestamp == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
  }

  Future<Map<String, dynamic>> getStats() async {
    final totalUsers = await countUsers();
    final lastSync = await getLastSyncDate();
    final hasSession = await hasValidSession();

    return {
      'totalUsers': totalUsers,
      'lastSyncDate': lastSync,
      'lastSyncFormatted': lastSync?.toIso8601String() ?? 'Nunca',
      'hasSession': hasSession,
      'adminCount': await _countAdmins(),
    };
  }

  Future<int> _countAdmins() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM $usersTable WHERE is_admin = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
