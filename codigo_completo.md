\n## Archivo: lib/db/app_database.dart\n```
export 'app_database_web.dart' if (dart.library.io) 'app_database_io.dart';
\n```\n
\n## Archivo: lib/db/app_database_io.dart\n```
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'daos/department_dao.dart';
import 'daos/efemeride_dao.dart';
import 'daos/local_dao.dart';
import 'daos/user_dao.dart';
import 'daos/worker_dao.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _database;

  late WorkerDao workerDao;
  late DepartmentDao departmentDao;
  late LocalDao localDao;
  late EfemerideDao efemerideDao;
  late UserDao userDao;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<AppDatabase> instance() async {
    final db = AppDatabase();
    await db.database;
    return db;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'phonebook_database.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await WorkerDao.createTable(db);
    await DepartmentDao.createTable(db);
    await LocalDao.createTable(db);
    await EfemerideDao.createTable(db);
    await UserDao.createTables(db);
  }

  Future<void> initializeDaos() async {
    final db = await database;
    workerDao = WorkerDao(db);
    departmentDao = DepartmentDao(db);
    localDao = LocalDao(db);
    efemerideDao = EfemerideDao(db);
    userDao = UserDao(db);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
\n```\n
\n## Archivo: lib/db/app_database_stub.dart\n```
// lib/db/app_database_stub.dart
class AppDatabase {
  static Future<AppDatabase> instance() async =>
      throw UnimplementedError('AppDatabase no disponible en esta plataforma');
  Future<void> initializeDaos() async {}
  Future<void> close() async {}
}
\n```\n
\n## Archivo: lib/db/app_database_web.dart\n```
// lib/db/app_database_web.dart
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Future<AppDatabase> instance() async => _instance;

  Future<void> initializeDaos() async {}
  Future<void> close() async {}
}
\n```\n
\n## Archivo: lib/db/daos/department_dao.dart\n```
import 'package:sqflite/sqflite.dart';
import '../../models/department_lite.dart';
import '../entities/department_entity.dart';
import '../../../../models/department.dart';

class DepartmentDao {
  final Database database;

  DepartmentDao(this.database);

  static const String tableName = 'departments';

  // Crear tabla
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        last_synced_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id) ON CONFLICT REPLACE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_departments_name 
      ON $tableName (name)
    ''');
  }

  // Insertar o actualizar
  Future<int> insertOrUpdate(DepartmentEntity department) async {
    return await database.insert(
      tableName,
      department.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar o actualizar múltiples
  Future<void> insertOrUpdateAll(List<DepartmentEntity> departments) async {
    final batch = database.batch();

    for (final department in departments) {
      batch.insert(
        tableName,
        department.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Obtener todos
  Future<List<DepartmentEntity>> getAllDepartments() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return maps.map((map) => DepartmentEntity.fromMap(map)).toList();
  }

  // Obtener por ID
  Future<DepartmentEntity?> getDepartmentById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return DepartmentEntity.fromMap(maps.first);
  }

  // Buscar por nombre
  Future<List<DepartmentEntity>> searchDepartments(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [searchTerm, searchTerm],
    );

    return maps.map((map) => DepartmentEntity.fromMap(map)).toList();
  }

  // Convertir a modelo
  Department toDepartmentModel(DepartmentEntity entity) {
    return Department(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      workers: null, // Los workers se cargan por separado
    );
  }

  // Convertir lista
  List<Department> toDepartmentModelList(List<DepartmentEntity> entities) {
    return entities.map(toDepartmentModel).toList();
  }

  // Obtener como modelos
  Future<List<Department>> getAllDepartmentsAsModels() async {
    final entities = await getAllDepartments();
    return toDepartmentModelList(entities);
  }

  // Eliminar por ID
  Future<int> deleteDepartment(int id) async {
    return await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Contar total
  Future<int> countDepartments() async {
    final result = await database.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener fecha de última sincronización
  Future<DateTime?> getLastSyncDate() async {
    final result = await database.rawQuery(
      'SELECT MAX(last_synced_at) FROM $tableName WHERE is_synced = 1',
    );

    final maxTimestamp = Sqflite.firstIntValue(result);
    if (maxTimestamp == null || maxTimestamp == 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
  }

  Future<List<DepartmentEntity>> getDepartmentsPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchTerm = '%$searchQuery%';
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      whereArgs.addAll([searchTerm, searchTerm]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map((map) => DepartmentEntity.fromMap(map)).toList();
  }

  // Obtener DepartmentLite paginado (modelo ligero)
  Future<List<DepartmentLite>> getDepartmentsLitePaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final entities = await getDepartmentsPaginated(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
    );

    return entities.map((entity) {
      final department = toDepartmentModel(entity);
      return DepartmentLite.fromDepartment(department);
    }).toList();
  }

  // Contar total con filtro de búsqueda
  Future<int> countDepartmentsWithFilter(String? searchQuery) async {
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchTerm = '%$searchQuery%';
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      whereArgs.addAll([searchTerm, searchTerm]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM $tableName${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener IDs de todos los departamentos (para caché)
  Future<List<int>> getAllDepartmentIds() async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      columns: ['id'],
    );

    return maps.map((map) => map['id'] as int).toList();
  }

  // Obtener batch de DepartmentLite por IDs
  Future<List<DepartmentLite>> getDepartmentsLiteByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT * FROM $tableName 
      WHERE id IN ($placeholders)
      ORDER BY name COLLATE NOCASE ASC
      ''', ids);

    return maps.map((map) {
      final entity = DepartmentEntity.fromMap(map);
      final department = toDepartmentModel(entity);
      return DepartmentLite.fromDepartment(department);
    }).toList();
  }
}
\n```\n
\n## Archivo: lib/db/daos/efemeride_dao.dart\n```
import 'package:sqflite/sqflite.dart';
import '../entities/efemeride_entity.dart';
import '../../../../models/efemeride.dart';

class EfemerideDao {
  final Database database;

  EfemerideDao(this.database);

  static const String tableName = 'efemerides';

  // Crear tabla con índices para búsqueda por fecha
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        fecha INTEGER NOT NULL,
        dato TEXT NOT NULL,
        detalle TEXT NOT NULL,
        last_synced_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id) ON CONFLICT REPLACE
      )
    ''');

    // Índices para búsqueda por fecha
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_efemerides_fecha 
      ON $tableName (fecha)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_efemerides_dato 
      ON $tableName (dato)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_efemerides_year_month 
      ON $tableName (strftime('%Y', fecha/1000, 'unixepoch'), 
                     strftime('%m', fecha/1000, 'unixepoch'))
    ''');
  }

  // Insertar o actualizar
  Future<int> insertOrUpdate(EfemerideEntity efemeride) async {
    return await database.insert(
      tableName,
      efemeride.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar o actualizar múltiples
  Future<void> insertOrUpdateAll(List<EfemerideEntity> efemerides) async {
    final batch = database.batch();

    for (final efemeride in efemerides) {
      batch.insert(
        tableName,
        efemeride.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Obtener todas
  Future<List<EfemerideEntity>> getAllEfemerides() async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      orderBy: 'fecha ASC',
    );
    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Obtener por ID
  Future<EfemerideEntity?> getEfemerideById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return EfemerideEntity.fromMap(maps.first);
  }

  // Obtener por fecha exacta
  Future<List<EfemerideEntity>> getEfemeridesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'fecha ASC',
    );

    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Obtener por mes
  Future<List<EfemerideEntity>> getEfemeridesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'fecha ASC',
    );

    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Obtener por año
  Future<List<EfemerideEntity>> getEfemeridesByYear(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'fecha ASC',
    );

    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Obtener efemérides próximas (próximos N días)
  Future<List<EfemerideEntity>> getUpcomingEfemerides(int days) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        now.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'fecha ASC',
    );

    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Buscar por texto en dato o detalle
  Future<List<EfemerideEntity>> searchEfemerides(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'dato LIKE ? OR detalle LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      orderBy: 'fecha ASC',
    );

    return maps.map((map) => EfemerideEntity.fromMap(map)).toList();
  }

  // Convertir a modelo
  Efemeride toEfemerideModel(EfemerideEntity entity) {
    return Efemeride(
      id: entity.id,
      fecha: entity.fecha,
      dato: entity.dato,
      detalle: entity.detalle,
    );
  }

  // Convertir lista
  List<Efemeride> toEfemerideModelList(List<EfemerideEntity> entities) {
    return entities.map(toEfemerideModel).toList();
  }

  // Obtener como modelos
  Future<List<Efemeride>> getAllEfemeridesAsModels() async {
    final entities = await getAllEfemerides();
    return toEfemerideModelList(entities);
  }

  // Eliminar por ID
  Future<int> deleteEfemeride(int id) async {
    return await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Contar total
  Future<int> countEfemerides() async {
    final result = await database.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener efemérides de hoy
  Future<List<Efemeride>> getTodayEfemerides() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'fecha ASC',
    );

    final entities = maps.map((map) => EfemerideEntity.fromMap(map)).toList();
    return toEfemerideModelList(entities);
  }

  // Obtener estadísticas por mes
  Future<Map<int, int>> getMonthlyStats(int year) async {
    final result = await database.rawQuery('''
      SELECT strftime('%m', fecha/1000, 'unixepoch') as month, 
             COUNT(*) as count
      FROM $tableName
      WHERE strftime('%Y', fecha/1000, 'unixepoch') = ?
      GROUP BY month
      ORDER BY month
    ''', [year.toString()]);

    final Map<int, int> stats = {};
    for (final row in result) {
      final month = int.tryParse(row['month'] as String) ?? 0;
      final count = row['count'] as int? ?? 0;
      if (month > 0) {
        stats[month] = count;
      }
    }

    return stats;
  }

  // Obtener fecha de última sincronización
  Future<DateTime?> getLastSyncDate() async {
    final result = await database.rawQuery(
      'SELECT MAX(last_synced_at) FROM $tableName WHERE is_synced = 1',
    );

    final maxTimestamp = Sqflite.firstIntValue(result);
    if (maxTimestamp == null || maxTimestamp == 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
  }
}\n```\n
\n## Archivo: lib/db/daos/local_dao.dart\n```
import 'package:sqflite/sqflite.dart';
import '../../models/local_lite.dart';
import '../entities/local_entity.dart';
import '../../../../models/local.dart';

class LocalDao {
  final Database database;

  LocalDao(this.database);

  static const String tableName = 'locals';

  // Crear tabla
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        last_synced_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id) ON CONFLICT REPLACE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_locals_name 
      ON $tableName (name)
    ''');
  }

  // Insertar o actualizar
  Future<int> insertOrUpdate(LocalEntity local) async {
    return await database.insert(
      tableName,
      local.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar o actualizar múltiples
  Future<void> insertOrUpdateAll(List<LocalEntity> locals) async {
    final batch = database.batch();

    for (final local in locals) {
      batch.insert(
        tableName,
        local.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Obtener todos
  Future<List<LocalEntity>> getAllLocals() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return maps.map((map) => LocalEntity.fromMap(map)).toList();
  }

  // Obtener por ID
  Future<LocalEntity?> getLocalById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalEntity.fromMap(maps.first);
  }

  // Buscar por nombre
  Future<List<LocalEntity>> searchLocals(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [searchTerm, searchTerm],
    );

    return maps.map((map) => LocalEntity.fromMap(map)).toList();
  }

  // Convertir a modelo
  Local toLocalModel(LocalEntity entity) {
    return Local(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      workers: null, // Los workers se cargan por separado
    );
  }

  // Convertir lista
  List<Local> toLocalModelList(List<LocalEntity> entities) {
    return entities.map(toLocalModel).toList();
  }

  // Obtener como modelos
  Future<List<Local>> getAllLocalsAsModels() async {
    final entities = await getAllLocals();
    return toLocalModelList(entities);
  }

  // Eliminar por ID
  Future<int> deleteLocal(int id) async {
    return await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Contar total
  Future<int> countLocals() async {
    final result = await database.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener fecha de última sincronización
  Future<DateTime?> getLastSyncDate() async {
    final result = await database.rawQuery(
      'SELECT MAX(last_synced_at) FROM $tableName WHERE is_synced = 1',
    );

    final maxTimestamp = Sqflite.firstIntValue(result);
    if (maxTimestamp == null || maxTimestamp == 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
  }

  Future<List<LocalEntity>> getLocalsPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchTerm = '%$searchQuery%';
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      whereArgs.addAll([searchTerm, searchTerm]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map((map) => LocalEntity.fromMap(map)).toList();
  }

  // Obtener LocalLite paginado (modelo ligero)
  Future<List<LocalLite>> getLocalsLitePaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final entities = await getLocalsPaginated(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
    );

    return entities.map((entity) {
      final local = toLocalModel(entity);
      return LocalLite.fromLocal(local);
    }).toList();
  }

  // Contar total con filtro de búsqueda
  Future<int> countLocalsWithFilter(String? searchQuery) async {
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchTerm = '%$searchQuery%';
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      whereArgs.addAll([searchTerm, searchTerm]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM $tableName${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener IDs de todos los locales (para caché)
  Future<List<int>> getAllLocalIds() async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      columns: ['id'],
    );

    return maps.map((map) => map['id'] as int).toList();
  }

  // Obtener batch de LocalLite por IDs
  Future<List<LocalLite>> getLocalsLiteByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT * FROM $tableName 
      WHERE id IN ($placeholders)
      ORDER BY name COLLATE NOCASE ASC
      ''', ids);

    return maps.map((map) {
      final entity = LocalEntity.fromMap(map);
      final local = toLocalModel(entity);
      return LocalLite.fromLocal(local);
    }).toList();
  }
}
\n```\n
\n## Archivo: lib/db/daos/user_dao.dart\n```
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
\n```\n
\n## Archivo: lib/db/daos/worker_dao.dart\n```
import 'package:sqflite/sqflite.dart';
import '../../models/department.dart';
import '../../models/local.dart';
import '../../models/worker_lite.dart';
import '../entities/worker_entity.dart';
import '../../../../models/worker.dart';

class WorkerDao {
  final Database database;

  WorkerDao(this.database);

  // Nombre de la tabla
  static const String tableName = 'workers';

  // Crear tabla
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        carnet_id TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        fecha_cumpleannos TEXT NOT NULL,
        departamento_id INTEGER,
        departamento_nombre TEXT,
        local_id INTEGER,
        local_nombre TEXT,
        last_synced_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id) ON CONFLICT REPLACE
      )
    ''');

    // Índices para búsquedas rápidas
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workers_name 
      ON $tableName (name, last_name)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workers_departamento 
      ON $tableName (departamento_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workers_local 
      ON $tableName (local_id)
    ''');
  }

  // Insertar o actualizar un worker
  Future<int> insertOrUpdate(WorkerEntity worker) async {
    return await database.insert(
      tableName,
      worker.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar o actualizar múltiples workers
  Future<void> insertOrUpdateAll(List<WorkerEntity> workers) async {
    final batch = database.batch();

    for (final worker in workers) {
      batch.insert(
        tableName,
        worker.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Obtener todos los workers
  Future<List<WorkerEntity>> getAllWorkers() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return maps.map((map) => WorkerEntity.fromMap(map)).toList();
  }

  // Obtener worker por ID
  Future<WorkerEntity?> getWorkerById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return WorkerEntity.fromMap(maps.first);
  }

  // Buscar workers por nombre o apellido
  Future<List<WorkerEntity>> searchWorkers(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'name LIKE ? OR last_name LIKE ? OR carnet_id LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
    );

    return maps.map((map) => WorkerEntity.fromMap(map)).toList();
  }

  // Obtener workers por departamento
  Future<List<WorkerEntity>> getWorkersByDepartment(int departmentId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'departamento_id = ?',
      whereArgs: [departmentId],
    );

    return maps.map((map) => WorkerEntity.fromMap(map)).toList();
  }

  // Obtener workers por local
  Future<List<WorkerEntity>> getWorkersByLocal(int localId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    return maps.map((map) => WorkerEntity.fromMap(map)).toList();
  }

  // Convertir WorkerEntity a Worker (modelo de API)
  Worker toWorkerModel(WorkerEntity entity) {
    return Worker(
      id: entity.id,
      name: entity.name,
      lastName: entity.lastName,
      carnetID: entity.carnetID,
      phone: entity.phone,
      address: entity.address,
      fechaCumpleannos: entity.fechaCumpleannos,
      department: entity.departamentoId != null
          ? Department(
              id: entity.departamentoId!,
              name: entity.departamentoNombre ?? '',
              phone: '',
            )
          : null,
      local: entity.localId != null
          ? Local(
              id: entity.localId!,
              name: entity.localNombre ?? '',
              phone: '',
            )
          : null,
    );
  }

  // Convertir lista de WorkerEntity a lista de Worker
  List<Worker> toWorkerModelList(List<WorkerEntity> entities) {
    return entities.map(toWorkerModel).toList();
  }

  // Obtener todos los workers como modelos
  Future<List<Worker>> getAllWorkersAsModels() async {
    final entities = await getAllWorkers();
    return toWorkerModelList(entities);
  }

  // Eliminar worker por ID
  Future<int> deleteWorker(int id) async {
    return await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Eliminar todos los workers
  Future<int> deleteAllWorkers() async {
    return await database.delete(tableName);
  }

  // Contar total de workers
  Future<int> countWorkers() async {
    final result = await database.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener fecha de última sincronización
  Future<DateTime?> getLastSyncDate() async {
    final result = await database.rawQuery(
      'SELECT MAX(last_synced_at) FROM $tableName WHERE is_synced = 1',
    );

    final maxTimestamp = Sqflite.firstIntValue(result);
    if (maxTimestamp == null || maxTimestamp == 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
  }

  // Marcar workers como no sincronizados
  Future<int> markAllAsNotSynced() async {
    return await database.update(tableName, {'is_synced': 0});
  }

  // AGREGAR estos métodos al final de la clase WorkerDao:

  // =============== MÉTODOS DE PAGINACIÓN ===============

  // Obtener workers paginados como WorkerEntity
  Future<List<WorkerEntity>> getWorkersPaged(int page, int limit) async {
    final offset = page * limit;

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      limit: limit,
      offset: offset,
      orderBy: 'name ASC, last_name ASC',
    );

    return maps.map((map) => WorkerEntity.fromMap(map)).toList();
  }

  // Obtener workers paginados como Worker (modelo completo)
  Future<List<Worker>> getWorkersPagedAsModels(int page, int limit) async {
    final entities = await getWorkersPaged(page, limit);
    return toWorkerModelList(entities);
  }

  // Obtener workers paginados como WorkerLite (optimizado para listas)
  Future<List<WorkerLite>> getWorkersLitePaged(int page, int limit) async {
    final offset = page * limit;

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      columns: [
        'id',
        'name',
        'last_name',
        'carnet_id',
        'phone',
        'fecha_cumpleannos',
        'departamento_id',
        'departamento_nombre',
        'local_id',
        'local_nombre',
      ],
      limit: limit,
      offset: offset,
      orderBy: 'name ASC, last_name ASC',
    );

    return maps.map((map) {
      final name = (map['name'] ?? '') as String;
      final lastName = (map['last_name'] ?? '') as String;

      return WorkerLite(
        id: map['id'] as int,
        name: name,
        lastName: lastName,
        carnetID: (map['carnet_id'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        initials: _calculateInitials(name, lastName),
        fullName: '$name $lastName'.trim(),
        departamentoID: map['departamento_id'] as int?,
        localId: map['local_id'] as int?,
        departmentName: (map['departamento_nombre'] ?? '') as String,
        localName: (map['local_nombre'] ?? '') as String,
        fechaCumpleannos: (map['fecha_cumpleannos'] ?? '') as String,
      );
    }).toList();
  }

  // Helper para calcular iniciales
  static String _calculateInitials(String name, String lastName) {
    if (name.isEmpty) return '??';
    final first = name[0];
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  // Buscar workers paginados
  Future<List<WorkerLite>> searchWorkersLitePaged(
    String query,
    int page,
    int limit,
  ) async {
    final offset = page * limit;
    final searchTerm = '%$query%';

    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      columns: [
        'id',
        'name',
        'last_name',
        'carnet_id',
        'phone',
        'fecha_cumpleannos',
        'departamento_id',
        'departamento_nombre',
        'local_id',
        'local_nombre',
      ],
      where: 'name LIKE ? OR last_name LIKE ? OR carnet_id LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
      limit: limit,
      offset: offset,
      orderBy: 'name ASC, last_name ASC',
    );

    return maps.map((map) {
      final name = (map['name'] ?? '') as String;
      final lastName = (map['last_name'] ?? '') as String;

      return WorkerLite(
        id: map['id'] as int,
        name: name,
        lastName: lastName,
        carnetID: (map['carnet_id'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        initials: _calculateInitials(name, lastName),
        fullName: '$name $lastName'.trim(),
        departamentoID: map['departamento_id'] as int?,
        localId: map['local_id'] as int?,
        departmentName: (map['departamento_nombre'] ?? '') as String,
        localName: (map['local_nombre'] ?? '') as String,
        fechaCumpleannos: (map['fecha_cumpleannos'] ?? '') as String,
      );
    }).toList();
  }

  // Obtener cumpleaños del mes paginados
  Future<List<WorkerLite>> getBirthdayWorkersPaged(int page, int limit) async {
    final offset = page * limit;
    final now = DateTime.now();
    final currentMonth = now.month;

    // Necesitamos todos los trabajadores para filtrar por fecha
    // Esto podría optimizarse con una columna de "mes_cumpleannos" en la tabla
    final allWorkers = await getAllWorkersAsModels();

    final birthdayWorkers = allWorkers
        .where((worker) => worker.birthdayDate?.month == currentMonth)
        .skip(offset)
        .take(limit)
        .map((worker) => WorkerLite.fromWorker(worker))
        .toList();

    return birthdayWorkers;
  }

  // Obtener total de páginas
  Future<int> getTotalPages(int limit) async {
    final totalCount = await countWorkers();
    return (totalCount / limit).ceil();
  }

  // Verificar si hay más datos
  Future<bool> hasMoreData(int currentPage, int limit) async {
    final totalCount = await countWorkers();
    final loadedCount = (currentPage + 1) * limit;
    return loadedCount < totalCount;
  }
}
\n```\n
\n## Archivo: lib/db/entities/department_entity.dart\n```
class DepartmentEntity {
  final int id;
  final String name;
  final String phone;
  final DateTime lastSyncedAt;
  final bool isSynced;

  DepartmentEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory DepartmentEntity.fromMap(Map<String, dynamic> map) {
    return DepartmentEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory DepartmentEntity.fromDepartmentModel(dynamic department) {
    return DepartmentEntity(
      id: department.id,
      name: department.name,
      phone: department.phone,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  DepartmentEntity copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
\n```\n
\n## Archivo: lib/db/entities/efemeride_entity.dart\n```
class EfemerideEntity {
  final int id;
  final DateTime fecha;
  final String dato;
  final String detalle;
  final DateTime lastSyncedAt;
  final bool isSynced;

  EfemerideEntity({
    required this.id,
    required this.fecha,
    required this.dato,
    required this.detalle,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory EfemerideEntity.fromMap(Map<String, dynamic> map) {
    return EfemerideEntity(
      id: map['id'] as int,
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int),
      dato: map['dato'] as String,
      detalle: map['detalle'] as String,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.millisecondsSinceEpoch,
      'dato': dato,
      'detalle': detalle,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory EfemerideEntity.fromEfemerideModel(dynamic efemeride) {
    return EfemerideEntity(
      id: efemeride.id,
      fecha: efemeride.fecha,
      dato: efemeride.dato,
      detalle: efemeride.detalle,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  EfemerideEntity copyWith({
    int? id,
    DateTime? fecha,
    String? dato,
    String? detalle,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return EfemerideEntity(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      dato: dato ?? this.dato,
      detalle: detalle ?? this.detalle,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Helper para obtener año, mes y día separados
  int get year => fecha.year;
  int get month => fecha.month;
  int get day => fecha.day;
}
\n```\n
\n## Archivo: lib/db/entities/local_entity.dart\n```
class LocalEntity {
  final int id;
  final String name;
  final String phone;
  final DateTime lastSyncedAt;
  final bool isSynced;

  LocalEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory LocalEntity.fromMap(Map<String, dynamic> map) {
    return LocalEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LocalEntity.fromLocalModel(dynamic local) {
    return LocalEntity(
      id: local.id,
      name: local.name,
      phone: local.phone,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  LocalEntity copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return LocalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
\n```\n
\n## Archivo: lib/db/entities/user_entity.dart\n```
class UserEntity {
  final int id;
  final String username;
  final String email;
  final String displayRole;
  final bool isAdmin;
  final DateTime lastSyncedAt;
  final bool isSynced;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.displayRole,
    required this.isAdmin,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      displayRole: map['display_role'] as String,
      isAdmin: map['is_admin'] == 1,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_role': displayRole,
      'is_admin': isAdmin ? 1 : 0,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory UserEntity.fromUserModel(dynamic user) {
    return UserEntity(
      id: user.id,
      username: user.username,
      email: user.email,
      displayRole: user.displayRole,
      isAdmin: user.isAdmin,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? displayRole,
    bool? isAdmin,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayRole: displayRole ?? this.displayRole,
      isAdmin: isAdmin ?? this.isAdmin,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

// Entidad para guardar sesión de usuario actual
class SessionEntity {
  final int userId;
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime loggedInAt;

  SessionEntity({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.loggedInAt,
  });

  factory SessionEntity.fromMap(Map<String, dynamic> map) {
    return SessionEntity(
      userId: map['user_id'] as int,
      token: map['token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      loggedInAt: DateTime.fromMillisecondsSinceEpoch(
        map['logged_in_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'token': token,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'logged_in_at': loggedInAt.millisecondsSinceEpoch,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
\n```\n
\n## Archivo: lib/db/entities/worker_entity.dart\n```
class WorkerEntity {
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String address;
  final String fechaCumpleannos;
  final int? departamentoId;
  final String? departamentoNombre;
  final int? localId;
  final String? localNombre;
  final DateTime lastSyncedAt;
  final bool isSynced;

  WorkerEntity({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.address,
    required this.fechaCumpleannos,
    this.departamentoId,
    this.departamentoNombre,
    this.localId,
    this.localNombre,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  // Convertir de JSON (base de datos) a entidad
  factory WorkerEntity.fromMap(Map<String, dynamic> map) {
    return WorkerEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      lastName: map['last_name'] as String,
      carnetID: map['carnet_id'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      fechaCumpleannos: map['fecha_cumpleannos'] as String,
      departamentoId: map['departamento_id'] as int?,
      departamentoNombre: map['departamento_nombre'] as String?,
      localId: map['local_id'] as int?,
      localNombre: map['local_nombre'] as String?,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  // Convertir de entidad a JSON (base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'carnet_id': carnetID,
      'phone': phone,
      'address': address,
      'fecha_cumpleannos': fechaCumpleannos,
      'departamento_id': departamentoId,
      'departamento_nombre': departamentoNombre,
      'local_id': localId,
      'local_nombre': localNombre,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Convertir desde el modelo de API (Worker) a entidad
  factory WorkerEntity.fromWorkerModel(dynamic worker) {
    return WorkerEntity(
      id: worker.id,
      name: worker.name,
      lastName: worker.lastName,
      carnetID: worker.carnetID,
      phone: worker.phone,
      address: worker.address,
      fechaCumpleannos: worker.fechaCumpleannos,
      departamentoId: worker.department?.id,
      departamentoNombre: worker.department?.name,
      localId: worker.local?.id,
      localNombre: worker.local?.name,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  WorkerEntity copyWith({
    int? id,
    String? name,
    String? lastName,
    String? carnetID,
    String? phone,
    String? address,
    String? fechaCumpleannos,
    int? departamentoId,
    String? departamentoNombre,
    int? localId,
    String? localNombre,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return WorkerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      carnetID: carnetID ?? this.carnetID,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      fechaCumpleannos: fechaCumpleannos ?? this.fechaCumpleannos,
      departamentoId: departamentoId ?? this.departamentoId,
      departamentoNombre: departamentoNombre ?? this.departamentoNombre,
      localId: localId ?? this.localId,
      localNombre: localNombre ?? this.localNombre,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
\n```\n
\n## Archivo: lib/generated/intl/messages_all.dart\n```
// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names, unnecessary_new
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'messages_en.dart' as messages_en;

typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> _deferredLibraries = {
  'en': () => new SynchronousFuture(null),
};

MessageLookupByLibrary? _findExact(String localeName) {
  switch (localeName) {
    case 'en':
      return messages_en.messages;
    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) {
  var availableLocale = Intl.verifiedLocale(
    localeName,
    (locale) => _deferredLibraries[locale] != null,
    onFailure: (_) => null,
  );
  if (availableLocale == null) {
    return new SynchronousFuture(false);
  }
  var lib = _deferredLibraries[availableLocale];
  lib == null ? new SynchronousFuture(false) : lib();
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  return new SynchronousFuture(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(String locale) {
  var actualLocale = Intl.verifiedLocale(
    locale,
    _messagesExistFor,
    onFailure: (_) => null,
  );
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
\n```\n
\n## Archivo: lib/generated/intl/messages_en.dart\n```
// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{};
}
\n```\n
\n## Archivo: lib/generated/l10n.dart\n```
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
\n```\n
\n## Archivo: lib/main.dart\n```
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n.dart';
import 'navigation/app_navigator.dart';
import 'providers/update_provider.dart';
import 'screen/directory/home_screen.dart';
import 'screen/directory/onboarding_screen.dart';
import 'services/notification_handler.dart';
import 'services/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/department_provider.dart';
import 'providers/local_provider.dart';
import 'providers/efemeride_provider.dart';
import 'utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationUtils.initialize();

  // Inicializar servicios
  await ServiceLocator().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider(create: (_) => LocalProvider()),
        ChangeNotifierProvider(create: (_) => EfemerideProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Directorio Telefónico',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: FutureBuilder<bool>(
          future: _checkOnboardingStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (snapshot.hasData && snapshot.data == false) {
              // Mostrar onboarding si no lo ha visto
              return OnboardingScreen(
                onComplete: () {
                  // Después del onboarding, mostrar el flujo normal
                  _showMainApp(context);
                },
              );
            }

            // Si ya vio el onboarding, mostrar app normal
            return _buildMainApp();
          },
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final widget = child ?? Container();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (authProvider.isAuthenticated) {
                    ServiceLocator().tokenExpiryManager.startMonitoring(
                      context,
                    );

                    // ========== AGREGAR VERIFICACIÓN DE ACTUALIZACIONES ==========
                    // Esperar un poco para que la app termine de cargar
                    Future.delayed(const Duration(seconds: 3), () {
                      if (context.mounted) {
                        final updateService = ServiceLocator().updateService;
                        // Solo verificar una vez por día
                        updateService.checkAndNotifyIfNeeded(context);
                      }
                    });
                  }
                });

                return widget;
              },
              child: child,
            ),
          );
        },
      ),
    );
  }

  // Método para verificar si ya vio el onboarding
  static Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      // En caso de error, asumir que no ha visto el onboarding
      return false;
    }
  }

  // Pantalla de loading mientras verifica
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        color: Colors.blue[700],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Directorio Telefónico',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Desoft',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget principal de la app
  Widget _buildMainApp() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar estado de autenticación al iniciar
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!authProvider.isLoading) {
            authProvider.checkAuthStatus();

            // ✅ VERIFICAR NOTIFICACIONES PENDIENTES
            final pendingNotification =
                await NotificationHandler.getPendingNotification();
            if (pendingNotification != null) {
              await NotificationHandler.clearPendingNotification();

              // Esperar y procesar
              Future.delayed(Duration(seconds: 2), () async {
                if (context.mounted) {
                  final updateService = ServiceLocator().updateService;

                  // Verificar actualización forzadamente
                  final updateInfo = await updateService.checkUpdates(
                    forceCheck: true,
                  );
                  if (updateInfo != null && context.mounted) {
                    updateService.showUpdateNotification(context, updateInfo);
                  }
                }
              });
            }

            // Verificación normal de actualizaciones (sin forzar)
            Future.delayed(Duration(seconds: 5), () {
              if (context.mounted) {
                final updateService = ServiceLocator().updateService;
                updateService.checkAndNotifyIfNeeded(context);
              }
            });
          }
        });

        // Mientras verifica, muestra loading
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Verificando sesión...'),
                ],
              ),
            ),
          );
        }

        // ✅ SIEMPRE mostrar HomeScreen (sin forzar login)
        return HomeScreen();
      },
    );
  }

  // Método para navegar al main app después del onboarding
  void _showMainApp(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => _buildMainApp()));
  }
}
\n```\n
\n## Archivo: lib/models/base_model.dart\n```
abstract class BaseModel {
  int get id;
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
\n```\n
\n## Archivo: lib/models/create_usuario_dto.dart\n```
class CreateUsuarioDto {
  final String nombreUsuario;
  final String email;
  final String password;
  final String rolNombre;

  CreateUsuarioDto({
    required this.nombreUsuario,
    required this.email,
    required this.password,
    required this.rolNombre,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'rolNombre': rolNombre,
    };
  }
}
\n```\n
\n## Archivo: lib/models/department.dart\n```
import 'base_model.dart';
import 'worker.dart';

class Department implements BaseModel {
  @override
  final int id;
  final String name;
  final String phone;
  final List<Worker>? workers;

  Department({
    required this.id,
    required this.name,
    required this.phone,
    this.workers,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['nombreDepartamento'] ?? '',
      phone: json['numeroFijoDepartamento'] ?? '',
      workers: (json['trabajadores'] as List<dynamic>?)
          ?.map((w) => Worker.fromJson(w))
          .toList(),
    );
  }

  Department copyWith({
    int? id,
    String? name,
    String? phone,
    List<Worker>? workers,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workers: workers ?? this.workers,
    );
  }

  // Helper methods
  int get workersCount => workers?.length ?? 0;
  bool get hasWorkers => workersCount > 0;

  // En department.dart, añade métodos DTO específicos:

  // Para crear un nuevo Departamento (POST)
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{'nombreDepartamento': name};

    // Solo incluir numeroFijoDepartamento si tiene valor
    if (phone.isNotEmpty) {
      dto['numeroFijoDepartamento'] = phone;
    }

    return dto;
  }

  // Para actualizar un Departamento existente (PUT)
  Map<String, dynamic> toUpdateDto() {
    final dto = <String, dynamic>{};

    // Ambos campos son opcionales en update (PartialType)
    if (name.isNotEmpty) {
      dto['nombreDepartamento'] = name;
    }

    // Enviar phone incluso si está vacío (para limpiarlo)
    dto['numeroFijoDepartamento'] = phone;

    return dto;
  }

  // Mantén toJson() para otros usos internos
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreDepartamento': name,
      'numeroFijoDepartamento': phone,
      'trabajadores': workers?.map((w) => w.toJson()).toList(),
    };
  }
}
\n```\n
\n## Archivo: lib/models/department_lite.dart\n```
import 'department.dart';
import 'worker.dart';

class DepartmentLite {
  final int id;
  final String name;
  final String phone;
  final String initials;
  final bool hasPhone;

  DepartmentLite({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
  }) : hasPhone = phone.isNotEmpty;

  // Factory desde JSON
  factory DepartmentLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombreDepartamento']);
    final phone = _parseString(json['numeroFijoDepartamento']);

    return DepartmentLite(
      id: json['id'] ?? 0,
      name: name,
      phone: phone,
      initials: _calculateInitials(name),
    );
  }

  // Factory desde Department completo
  factory DepartmentLite.fromDepartment(Department department) {
    return DepartmentLite(
      id: department.id,
      name: department.name,
      phone: department.phone,
      initials: _calculateInitials(department.name),
    );
  }

  // Métodos estáticos auxiliares
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name) {
    if (name.isEmpty) return '??';

    // Tomar las primeras 2 letras o la primera si solo hay una palabra
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  // Convertir a Department completo
  Department toDepartment({List<Worker>? workers}) {
    return Department(
      id: id,
      name: name,
      phone: phone,
      workers: workers!.map((w) => w).toList(),
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'DepartmentLite(id: $id, name: $name, phone: $phone)';
  }
}
\n```\n
\n## Archivo: lib/models/efemeride.dart\n```
import 'base_model.dart';

class Efemeride implements BaseModel {
  @override
  final int id;
  final DateTime fecha;
  final String dato;
  final String detalle;

  Efemeride({
    required this.id,
    required this.fecha,
    required this.dato,
    required this.detalle,
  });

  factory Efemeride.fromJson(Map<String, dynamic> json) {
    return Efemeride(
      id: json['id'] ?? 0,
      fecha: json['fechaEfemeride'] != null
          ? DateTime.parse(json['fechaEfemeride'])
          : DateTime.now(),
      dato: json['datoEfemeride'] ?? '',
      detalle: json['detalleEfemeride'] ?? '',
    );
  }

  // Para uso interno en la app
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  // Para crear en el backend (POST)
  Map<String, dynamic> toCreateDto() {
    return {
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  // Para actualizar en el backend (PUT)
  Map<String, dynamic> toUpdateDto() {
    return {
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  Efemeride copyWith({
    int? id,
    DateTime? fecha,
    String? dato,
    String? detalle,
  }) {
    return Efemeride(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      dato: dato ?? this.dato,
      detalle: detalle ?? this.detalle,
    );
  }

  // Helper methods
  String get formattedDate => "${fecha.day}/${fecha.month}/${fecha.year}";

  String get isoDate => fecha.toIso8601String().split('T')[0];

  bool get isToday {
    final now = DateTime.now();
    return fecha.day == now.day &&
        fecha.month == now.month &&
        fecha.year == now.year;
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return fecha.month == now.month && fecha.year == now.year;
  }

  // Para mostrar en UI con nombres de meses en español
  String get displayDate {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${fecha.day} de ${months[fecha.month - 1]} de ${fecha.year}';
  }

  // Método para obtener la fecha sin año (para calendario anual)
  String get dateWithoutYear {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${months[fecha.month - 1]}';
  }

  // Para comparar por fecha (ignorando hora)
  bool isSameDate(DateTime other) {
    return fecha.year == other.year &&
        fecha.month == other.month &&
        fecha.day == other.day;
  }
}
\n```\n
\n## Archivo: lib/models/event.dart\n```
import 'efemeride.dart';
import 'worker.dart';

enum EventType { birthday, efemeride }

class Event {
  final String title;
  final EventType type;
  final DateTime date;
  final Worker? worker;
  final Efemeride? efemeride;

  Event({
    required this.title,
    required this.type,
    required this.date,
    this.worker,
    this.efemeride,
  });

  // Helper methods
  bool get isToday {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month;
  }

  String get formattedDate {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get displayDate => "${date.day}/${date.month}/${date.year}";
}
\n```\n
\n## Archivo: lib/models/local.dart\n```
import 'base_model.dart';
import 'worker.dart';

class Local implements BaseModel {
  @override
  final int id;
  final String name;
  final String phone;
  final List<Worker>? workers;

  Local({
    required this.id,
    required this.name,
    required this.phone,
    this.workers,
  });

  factory Local.fromJson(Map<String, dynamic> json) {
    return Local(
      id: json['id'] ?? 0,
      name: json['nombreLocal'] ?? '',
      phone: json['numeroFijoLocal'] ?? '',
      workers: (json['trabajadores'] as List<dynamic>?)
          ?.map((w) => Worker.fromJson(w))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreLocal': name,
      'numeroFijoLocal': phone,
      'trabajadores': workers?.map((w) => w.toJson()).toList(),
    };
  }

  Local copyWith({
    int? id,
    String? name,
    String? phone,
    List<Worker>? workers,
  }) {
    return Local(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workers: workers ?? this.workers,
    );
  }

  // Helper methods
  int get workersCount => workers?.length ?? 0;
  bool get hasWorkers => workersCount > 0;

  // En local.dart, añade estos métodos:

  // Para crear un nuevo Local (POST) - solo lo que el backend espera
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{'nombreLocal': name};

    // Solo incluir numeroFijoLocal si tiene valor
    if (phone.isNotEmpty) {
      dto['numeroFijoLocal'] = phone;
    }

    return dto;
  }

  // Para actualizar un Local existente (PUT)
  Map<String, dynamic> toUpdateDto() {
    final dto = <String, dynamic>{};

    // Ambos campos son opcionales en update (PartialType)
    if (name.isNotEmpty) {
      dto['nombreLocal'] = name;
    }

    // Enviar phone incluso si está vacío (para limpiarlo)
    dto['numeroFijoLocal'] = phone;

    return dto;
  }
}
\n```\n
\n## Archivo: lib/models/local_lite.dart\n```
import 'local.dart';
import 'worker.dart';

class LocalLite {
  final int id;
  final String name;
  final String phone;
  final String initials;
  final bool hasPhone;

  LocalLite({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
  }) : hasPhone = phone.isNotEmpty;

  factory LocalLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombreLocal']);
    final phone = _parseString(json['numeroFijoLocal']);

    return LocalLite(
      id: json['id'] ?? 0,
      name: name,
      phone: phone,
      initials: _calculateInitials(name),
    );
  }

  factory LocalLite.fromLocal(Local local) {
    return LocalLite(
      id: local.id,
      name: local.name,
      phone: local.phone,
      initials: _calculateInitials(local.name),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name) {
    if (name.isEmpty) return '??';

    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Local toLocal({List<Worker>? workers}) {
    return Local(
      id: id,
      name: name,
      phone: phone,
      workers: workers?.map((w) => w).toList(),
    );
  }

  @override
  String toString() {
    return 'LocalLite(id: $id, name: $name, phone: $phone)';
  }
}
\n```\n
\n## Archivo: lib/models/rol.dart\n```
import 'base_model.dart';

class Rol implements BaseModel {
  @override
  final int id;
  final String nombre;

  Rol({required this.id, required this.nombre});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(id: json['id'] ?? 0, nombre: json['rolNombre'] ?? '');
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'rolNombre': nombre};
  }

  Rol copyWith({int? id, String? nombre}) {
    return Rol(id: id ?? this.id, nombre: nombre ?? this.nombre);
  }

  // Roles predefinidos según el backend
  static Rol get admin => Rol(id: 1, nombre: 'admin');
  static Rol get consult =>
      Rol(id: 2, nombre: 'consult'); // Cambiado de 'user' a 'consult'

  // Lista de todos los roles válidos
  static List<Rol> get all => [admin, consult];

  // Verificar si un string es un rol válido
  static bool isValidRol(String rolName) {
    return rolName == 'admin' || rolName == 'consult';
  }
}
\n```\n
\n## Archivo: lib/models/update_info.dart\n```
class UpdateInfo {
  final String latestVersion;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool mandatory;
  final String? minSupportedVersion;

  UpdateInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.mandatory,
    this.minSupportedVersion,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      apkUrl: json['apk_url'] ?? '',
      releaseNotes: json['release_notes'] ?? 'Actualización disponible',
      mandatory: json['mandatory'] ?? false,
      minSupportedVersion: json['min_supported_version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'version_code': versionCode,
      'apk_url': apkUrl,
      'release_notes': releaseNotes,
      'mandatory': mandatory,
      'min_supported_version': minSupportedVersion,
    };
  }

  @override
  String toString() {
    return 'UpdateInfo{latestVersion: $latestVersion, versionCode: $versionCode, mandatory: $mandatory}';
  }
}
\n```\n
\n## Archivo: lib/models/user.dart\n```
import 'base_model.dart';
import 'create_usuario_dto.dart';
import 'rol.dart';

class User implements BaseModel {
  @override
  final int id;
  final String username;
  final String email;
  final String password;
  final List<Rol> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.roles,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['nombreUsuario'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((role) {
            if (role is Map<String, dynamic>) {
              return Rol.fromJson(role);
            } else if (role is String) {
              // Si es string, buscar el rol correspondiente
              if (role.toLowerCase() == 'admin') {
                return Rol.admin;
              } else {
                return Rol.consult;
              }
            } else {
              return Rol.consult; // Por defecto
            }
          }).toList() ??
          [Rol.consult],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreUsuario': username,
      'email': email,
      'password': password,
      'roles': roles.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Método para crear DTO para registro
  CreateUsuarioDto toCreateDto(String rolNombre) {
    return CreateUsuarioDto(
      nombreUsuario: username,
      email: email,
      password: password,
      rolNombre: rolNombre,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    List<Rol>? roles,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods usando tu modelo Rol
  bool get isAdmin => roles.any((role) => role.nombre.toLowerCase() == 'admin');
  bool get isConsult =>
      roles.any((role) => role.nombre.toLowerCase() == 'consult'); // Cambiado

  String get primaryRoleName => roles.isNotEmpty
      ? roles.first.nombre
      : 'consult'; // Por defecto 'consult'

  // Método para mostrar rol en UI
  String get displayRole {
    if (isAdmin) return 'Administrador';
    if (isConsult) return 'Consultor'; // Cambiado de 'Usuario' a 'Consultor'
    return 'Consultor';
  }
}
\n```\n
\n## Archivo: lib/models/worker.dart\n```
import 'package:flutter/material.dart';

import 'base_model.dart';
import 'department.dart';
import 'local.dart';
import 'worker_lite.dart'; // Para la factory fromLite

class Worker implements BaseModel {
  @override
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String address;
  final String fechaCumpleannos;
  final Department? department;
  final Local? local;
  final int? cumpleannoId;

  DateTime? _cachedBirthdayDate;
  String? _cachedFormattedBirthday;
  String? _cachedFullName;
  String? _cachedInitials;
  String? _cachedPosition;
  String? _cachedSubdirection;
  bool? _cachedHasPhone;
  bool? _cachedHasDepartment;
  bool? _cachedHasLocal;
  bool? _cachedHasBirthday;

  // Constructor NORMAL (no const)
  Worker({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.address,
    required this.fechaCumpleannos,
    this.department,
    this.local,
    this.cumpleannoId,
  });

  // FACTORY desde JSON - MÁS EFICIENTE
  factory Worker.fromJson(Map<String, dynamic> json) {
    final worker = Worker(
      id: json['id'] ?? 0,
      name: _parseString(json['nombre']),
      lastName: _parseString(json['apellido']),
      carnetID: _parseString(json['carnetIdentidad']),
      address: _parseString(json['direccion']),
      phone: _parseString(json['numeroCelular']),
      fechaCumpleannos: _parseString(json['fechaCumpleanno']),
      department: json['departamento'] != null
          ? Department.fromJson(Map<String, dynamic>.from(json['departamento']))
          : null,
      local: json['local'] != null
          ? Local.fromJson(Map<String, dynamic>.from(json['local']))
          : null,
      cumpleannoId: json['cumpleannoId'],
    );

    // Inicializar caché después de crear la instancia
    worker._initializeCache();

    return worker;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // Factory para crear desde entidad
  factory Worker.fromEntity(Map<String, dynamic> entity) {
    final worker = Worker(
      id: entity['id'] ?? 0,
      name: _parseString(entity['nombre']),
      lastName: _parseString(entity['apellido']),
      carnetID: _parseString(entity['carnetIdentidad']),
      address: _parseString(entity['direccion']),
      phone: _parseString(entity['numeroCelular']),
      fechaCumpleannos: _parseString(entity['fechaCumpleanno']),
    );

    worker._initializeCache();
    return worker;
  }

  // Factory desde WorkerLite
  factory Worker.fromLite(
    WorkerLite lite, {
    Department? department,
    Local? local,
  }) {
    // Si no se pasan department/local como parámetros, intentar crearlos desde los datos disponibles en lite
    final resolvedDepartment =
        department ??
        (lite.departamentoID != null && lite.departmentName != null
            ? Department(
                id: lite.departamentoID!,
                name: lite.departmentName!,
                phone: '',
              )
            : null);

    final resolvedLocal =
        local ??
        (lite.localId != null && lite.localName != null
            ? Local(id: lite.localId!, name: lite.localName!, phone: '')
            : null);

    final worker = Worker(
      id: lite.id,
      name: lite.name,
      lastName: lite.lastName,
      carnetID: lite.carnetID,
      phone: lite.phone,
      address: '', // No disponible en lite
      fechaCumpleannos: lite.fechaCumpleannos ?? '',
      department: resolvedDepartment,
      local: resolvedLocal,
    );

    worker._initializeCache();
    return worker;
  }

  // MÉTODO PARA INICIALIZAR CACHÉ (llamar después de construir)
  void _initializeCache() {
    // Calcular y cachear propiedades una sola vez
    _cachedFullName = '$name $lastName'.trim();
    _cachedInitials = _calculateInitials();
    _cachedBirthdayDate = _parseBirthdayDateOptimized();
    _cachedFormattedBirthday = _formatBirthdayOptimized();
    _cachedPosition = department?.name ?? 'Sin departamento';
    _cachedSubdirection = local?.name ?? 'Sin local';
    _cachedHasPhone = phone.isNotEmpty;
    _cachedHasDepartment = department != null;
    _cachedHasLocal = local != null;
    _cachedHasBirthday = fechaCumpleannos.isNotEmpty;
  }

  // MÉTODOS PRIVADOS DE CÁLCULO
  String _calculateInitials() {
    if (name.isEmpty) return '??';
    final first = name[0];
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  DateTime? _parseBirthdayDateOptimized() {
    if (fechaCumpleannos.isEmpty) return null;

    // FORMATO 1: Texto español "17 de septiembre"
    try {
      final parts = fechaCumpleannos.toLowerCase().split(' de ');
      if (parts.length == 2) {
        final dayStr = parts[0].trim();
        final monthStr = parts[1].trim();

        final day = int.tryParse(dayStr);
        if (day == null) return null;

        // Mapeo de meses en español
        final monthMap = {
          'enero': 1,
          'febrero': 2,
          'marzo': 3,
          'abril': 4,
          'mayo': 5,
          'junio': 6,
          'julio': 7,
          'agosto': 8,
          'septiembre': 9,
          'octubre': 10,
          'noviembre': 11,
          'diciembre': 12,
          'ene': 1,
          'feb': 2,
          'mar': 3,
          'abr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'ago': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dic': 12,
        };

        final month = monthMap[monthStr];
        if (month != null) {
          final now = DateTime.now();
          final year = now.year; // Usar año actual para calendario

          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando español: $e');
    }

    // FORMATO 2: YYYY-MM-DD (ISO)
    try {
      final date = DateTime.parse(fechaCumpleannos);
      return date;
    } catch (_) {
      // Continuar con otros formatos
    }

    // FORMATO 3: dd/MM/yyyy
    try {
      final parts = fechaCumpleannos.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      // No se pudo parsear
    }

    // FORMATO 4: dd-MM-yyyy
    try {
      final parts = fechaCumpleannos.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      // No se pudo parsear
    }

    return null;
  }

  String _formatBirthdayOptimized() {
    if (fechaCumpleannos.isEmpty) return 'Fecha no disponible';

    final date = _cachedBirthdayDate;
    if (date == null) {
      // Si ya está en formato texto español, devolver tal cual
      if (_isSpanishTextFormat(fechaCumpleannos)) {
        return fechaCumpleannos;
      }
      return fechaCumpleannos;
    }

    // Convertir a formato texto español
    final monthNames = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${monthNames[date.month - 1]}';
  }

  bool _isSpanishTextFormat(String date) {
    final lowercase = date.toLowerCase();
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months.any((month) => lowercase.contains(month)) &&
        lowercase.contains(' de ');
  }

  // GETTERS QUE USAN CACHÉ
  String get fullName => _cachedFullName ?? '$name $lastName'.trim();
  String get initials => _cachedInitials ?? _calculateInitials();
  String get position =>
      _cachedPosition ?? department?.name ?? 'Sin departamento';
  String get subdirection => _cachedSubdirection ?? local?.name ?? 'Sin local';
  DateTime? get birthdayDate =>
      _cachedBirthdayDate ?? _parseBirthdayDateOptimized();
  String get formattedBirthday =>
      _cachedFormattedBirthday ?? _formatBirthdayOptimized();
  bool get hasPhone => _cachedHasPhone ?? phone.isNotEmpty;
  bool get hasDepartment => _cachedHasDepartment ?? (department != null);
  bool get hasLocal => _cachedHasLocal ?? (local != null);
  bool get hasBirthday => _cachedHasBirthday ?? fechaCumpleannos.isNotEmpty;

  String get formattedBirthdayWithYear {
    final date = birthdayDate;
    if (date == null) return formattedBirthday;

    final monthNames = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${monthNames[date.month - 1]} de ${date.year}';
  }

  bool get hasBirthdayThisMonth {
    final now = DateTime.now();
    final birthday = birthdayDate;
    return birthday != null && birthday.month == now.month;
  }

  bool get hasBirthdayToday {
    final now = DateTime.now();
    final birthday = birthdayDate;
    return birthday != null &&
        birthday.month == now.month &&
        birthday.day == now.day;
  }

  // Métodos de utilidad para IDs
  int? get departamentoID => department?.id;
  int? get localId => local?.id;

  // Para crear DTOs para el backend
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{};
    dto['nombre'] = name;
    dto['apellido'] = lastName;
    dto['carnetIdentidad'] = carnetID;
    if (address.isNotEmpty) dto['direccion'] = address;
    if (phone.isNotEmpty) dto['numeroCelular'] = phone;
    if (fechaCumpleannos.isNotEmpty) dto['fechaCumpleanno'] = fechaCumpleannos;
    if (departamentoID != null && departamentoID! > 0) {
      dto['departamentoId'] = departamentoID;
    }
    if (localId != null && localId! > 0) {
      dto['localId'] = localId;
    }
    return dto;
  }

  Map<String, dynamic> toUpdateDto() {
    final dto = toCreateDto();
    return dto;
  }

  Worker copyWith({
    int? id,
    String? name,
    String? lastName,
    String? carnetID,
    String? phone,
    String? address,
    String? fechaCumpleannos,
    Department? department,
    Local? local,
    int? cumpleannoId,
  }) {
    final worker = Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      carnetID: carnetID ?? this.carnetID,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      fechaCumpleannos: fechaCumpleannos ?? this.fechaCumpleannos,
      department: department ?? this.department,
      local: local ?? this.local,
      cumpleannoId: cumpleannoId ?? this.cumpleannoId,
    );

    worker._initializeCache();
    return worker;
  }

  // Validaciones
  bool get isValid => carnetID.isNotEmpty && name.isNotEmpty;

  List<String> validate() {
    final errors = <String>[];
    if (name.isEmpty) errors.add('El nombre es requerido');
    if (carnetID.isEmpty) errors.add('El carnet de identidad es requerido');
    if (carnetID.length != 11) errors.add('El carnet debe tener 11 dígitos');
    return errors;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'apellido': lastName,
      'carnetIdentidad': carnetID,
      'direccion': address,
      'numeroCelular': phone,
      'fechaCumpleanno': fechaCumpleannos,
      'departamento': department?.toJson(),
      'local': local?.toJson(),
      'cumpleannoId': cumpleannoId,
    };
  }

  // En worker.dart, agregar método optimizado para calendario:
  DateTime? get birthdayDateForCalendar {
    if (_cachedBirthdayDate != null) return _cachedBirthdayDate;

    // Versión optimizada solo para calendario (sin prints)
    if (fechaCumpleannos.isEmpty) return null;

    // Formato texto español (prioridad)
    final parts = fechaCumpleannos.toLowerCase().split(' de ');
    if (parts.length == 2) {
      final dayStr = parts[0].trim();
      final monthStr = parts[1].trim();

      final day = int.tryParse(dayStr);
      if (day == null) return null;

      final monthMap = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'junio': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
      };

      final month = monthMap[monthStr];
      if (month != null) {
        final now = DateTime.now();
        return DateTime(now.year, month, day);
      }
    }

    return _cachedBirthdayDate; // Fallback al caché existente
  }

  @override
  String toString() {
    return 'Worker(id: $id, name: $fullName)';
  }
}
\n```\n
\n## Archivo: lib/models/worker_lite.dart\n```
import 'department.dart';
import 'local.dart';
import 'worker.dart';

class WorkerLite {
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String initials;
  final String fullName;
  final bool hasPhone;
  final int? departamentoID;
  final int? localId;
  final String? departmentName;
  final String? localName;
  final String? fechaCumpleannos;

  WorkerLite({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.initials,
    required this.fullName,
    this.departamentoID,
    this.localId,
    this.departmentName,
    this.localName,
    this.fechaCumpleannos,
  }) : hasPhone = phone.isNotEmpty;

  // Factory desde JSON ligero (para API paginada)
  factory WorkerLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombre']);
    final lastName = _parseString(json['apellido']);
    final carnetID = _parseString(json['carnetIdentidad']);
    final phone = _parseString(json['numeroCelular']);

    // Extraer departamento (puede venir como objeto o como ID)
    int? departamentoID;
    String? departmentName;
    if (json['departamento'] is Map) {
      departamentoID = json['departamento']['id'];
      departmentName =
          json['departamento']['nombreDepartamento'] ??
          json['departamento']['nombre'];
    } else {
      departamentoID = json['departamentoId'];
      // Si solo tenemos ID, no tenemos el nombre
    }

    // Extraer local (puede venir como objeto o como ID)
    int? localId;
    String? localName;
    if (json['local'] is Map) {
      localId = json['local']['id'];
      localName = json['local']['nombreLocal'] ?? json['local']['nombre'];
    } else {
      localId = json['localId'];
      // Si solo tenemos ID, no tenemos el nombre
    }

    return WorkerLite(
      id: json['id'] ?? 0,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      initials: _calculateInitials(name, lastName),
      fullName: '$name $lastName'.trim(),
      departamentoID: departamentoID,
      localId: localId,
      departmentName: departmentName,
      localName: localName,
      fechaCumpleannos: _parseString(json['fechaCumpleanno']),
    );
  }

  // Factory desde Worker completo (para convertir de cache)
  factory WorkerLite.fromWorker(Worker worker) {
    return WorkerLite(
      id: worker.id,
      name: worker.name,
      lastName: worker.lastName,
      carnetID: worker.carnetID,
      phone: worker.phone,
      initials: worker.initials,
      fullName: worker.fullName,
      departamentoID: worker.departamentoID,
      localId: worker.localId,
      departmentName: worker.department?.name,
      localName: worker.local?.name,
      fechaCumpleannos: worker.fechaCumpleannos,
    );
  }

  // Métodos estáticos auxiliares
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name, String lastName) {
    if (name.isEmpty) return '??';
    final first = name[0];
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  // Convertir a Worker completo (cuando se necesite detalles)
  Worker toWorker({Department? department, Local? local}) {
    // Si no se pasan department/local como parámetros, intentar crearlos desde los datos disponibles
    final resolvedDepartment =
        department ??
        (departamentoID != null && departmentName != null
            ? Department(id: departamentoID!, name: departmentName!, phone: '')
            : null);

    final resolvedLocal =
        local ??
        (localId != null && localName != null
            ? Local(id: localId!, name: localName!, phone: '')
            : null);

    return Worker(
      id: id,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      address: '', // No disponible en lite
      fechaCumpleannos: fechaCumpleannos ?? '',
      department: resolvedDepartment,
      local: resolvedLocal,
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'WorkerLite(id: $id, name: $fullName, phone: $phone)';
  }
}
\n```\n
\n## Archivo: lib/navigation/app_navigator.dart\n```
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
\n```\n
\n## Archivo: lib/providers/auth_provider.dart\n```
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rol.dart';
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth_security_service.dart';
import '../services/service_locator.dart';
import '../utils/validators.dart';
import '../utils/error_messages.dart';

class AuthProvider extends ChangeNotifier {
  // Servicios
  final AuthService _authService = ServiceLocator().authService;
  final AuthSecurityService _securityService =
      ServiceLocator().authSecurityService;

  // Estados principales
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;
  User? _user;

  // Estados para compatibilidad
  bool _loading = false;
  String? _error;
  bool _checkingAuth = true;
  bool _hasCheckedAuth = false;
  String? _token;

  // ✅ CONTROLES PARA EVITAR BUCLES Y NOTIFICACIONES INNECESARIAS
  bool _isCheckingAuthStatus = false;
  DateTime? _lastAuthCheck;
  static const Duration _authCheckCooldown = Duration(seconds: 30);

  // ✅ CONTROL DE NOTIFICACIONES
  User? _previousUser;
  bool _previousAuthState = false;
  bool _previousLoadingState = true;

  // Getters principales
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  // Getters para compatibilidad
  bool get loading => _loading;
  String? get error => _error;
  bool get isCheckingAuth => _checkingAuth;
  bool get hasCheckedAuth => _hasCheckedAuth;
  String? get token => _token;

  // Constructor optimizado
  AuthProvider() {
    _initializeDelayed();
  }

  void _initializeDelayed() {
    // Pequeño delay para evitar conflictos con inicialización de servicios
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_hasCheckedAuth && !_isCheckingAuthStatus) {
        _performAuthCheck();
      }
    });
  }

  // ✅ MÉTODO PÚBLICO para verificar estado (con cooldown)
  Future<void> checkAuthStatus({bool force = false}) async {
    // Si ya se está verificando, salir
    if (_isCheckingAuthStatus) {
      return;
    }

    // Verificar cooldown (a menos que force=true)
    if (!force &&
        _lastAuthCheck != null &&
        DateTime.now().difference(_lastAuthCheck!) < _authCheckCooldown) {
      return;
    }

    await _performAuthCheck();
  }

  // ✅ MÉTODO PRIVADO para la verificación real
  Future<void> _performAuthCheck() async {
    _isCheckingAuthStatus = true;
    _lastAuthCheck = DateTime.now();

    if (!_isLoading) {
      _isLoading = true;
      _loading = true;
      _checkingAuth = true;
      _safeNotifyListeners(); // Notificar cambio de estado loading
    }

    try {
      // Obtener token del gestor seguro
      _token = await ServiceLocator().secureTokenManager.getToken();

      if (_token != null && _token!.isNotEmpty) {
        try {
          // Intentar obtener usuario del servicio (con timeout)
          final userResponse = await _authService.getCurrentUser().timeout(
            const Duration(seconds: 10),
          );

          if (!userResponse.hasError && userResponse.data != null) {
            _user = userResponse.data;
            _isAuthenticated = true;
            _errorMessage = null;
            _error = null;
          } else {
            _handleInvalidToken(userResponse);
          }
        } catch (e) {
          // En caso de error de conexión, mantener estado actual
          // No limpiar el token porque puede ser solo un problema temporal
        }
      } else {
        _user = null;
        _isAuthenticated = false;
        _errorMessage = null;
        _error = null;
      }
    } catch (e) {
      _errorMessage = 'Error verificando sesión';
      _error = e.toString();
    } finally {
      _isLoading = false;
      _loading = false;
      _checkingAuth = false;
      _hasCheckedAuth = true;
      _isCheckingAuthStatus = false;
      _safeNotifyListeners(); // Notificar cambio de estado final
    }
  }

  void _handleInvalidToken(dynamic response) {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = response.error;
    _error = response.error;

    // Solo limpiar token si es específicamente un error 401
    if (response.statusCode == 401) {
      ServiceLocator().secureTokenManager.deleteToken().then((_) {
        _token = null;
      });
    }
  }

  // ✅ LOGIN REAL con backend usando AuthService
  Future<bool> login(
    String usernameOrEmail,
    String password, {
    bool forceRefresh = false,
  }) async {
    // Validaciones iniciales
    final usernameError = _validateUsernameOrEmail(usernameOrEmail);
    final passwordError = Validators.validatePassword(password);

    if (usernameError != null || passwordError != null) {
      _errorMessage = usernameError ?? passwordError!;
      _error = usernameError ?? passwordError!;
      _safeNotifyListeners();
      return false;
    }

    // Verificar rate limiting
    if (!await _securityService.canAttemptLogin()) {
      final lockoutTime = await _securityService.getLockoutTime();
      final remainingTime = lockoutTime?.difference(DateTime.now());

      if (remainingTime != null) {
        final minutes = remainingTime.inMinutes;
        final seconds = remainingTime.inSeconds % 60;
        _errorMessage =
            '⚠️ Demasiados intentos fallidos. Espere $minutes:${seconds.toString().padLeft(2, '0')} minutos.';
        _error = _errorMessage;
      } else {
        _errorMessage = '⚠️ Demasiados intentos fallidos. Espere 15 minutos.';
        _error = _errorMessage;
      }

      _safeNotifyListeners();
      return false;
    }

    // Verificar conexión a internet
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasConnection) {
        _errorMessage = ErrorMessages.noInternet;
        _error = _errorMessage;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando conectividad: $e');
    }

    _isLoading = true;
    _loading = true;
    _errorMessage = null;
    _error = null;
    _safeNotifyListeners();

    try {
      final response = await _authService
          .login(usernameOrEmail, password)
          .timeout(const Duration(seconds: 15));

      if (response.hasError) {
        _errorMessage = response.error ?? ErrorMessages.invalidCredentials;
        _error = _errorMessage;

        await _securityService.recordFailedAttempt();
        final remainingAttempts = await _securityService.getRemainingAttempts();

        if (remainingAttempts > 0) {
          _errorMessage =
              '${_errorMessage ?? ""}\n🔄 Intentos: $remainingAttempts';
        } else {
          _errorMessage = '${_errorMessage ?? ""}\n🔒 Cuenta bloqueada';
        }

        _isLoading = false;
        _loading = false;
        _safeNotifyListeners();
        return false;
      } else {
        _user = response.data;
        _isAuthenticated = true;
        _hasCheckedAuth = true;

        _token = await ServiceLocator().secureTokenManager.getToken();

        await _securityService.resetAttempts();

        final prefs = await SharedPreferences.getInstance();
        if (_user != null) {
          await prefs.setString('user_email', _user!.email);
          await prefs.setString('user_name', _user!.username);
        }

        // ✅ RESETEAR EL COOLDOWN después de login exitoso
        _lastAuthCheck = DateTime.now();

        _isLoading = false;
        _loading = false;
        _safeNotifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _loading = false;
      _errorMessage = ErrorMessages.fromException(e);
      _error = _errorMessage;

      if (!_errorMessage!.contains('conexión') &&
          !_errorMessage!.contains('internet')) {
        await _securityService.recordFailedAttempt();
      }

      _safeNotifyListeners();
      return false;
    }
  }

  // ✅ Método para refrescar token
  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refreshAccessToken();

      if (response.hasError) {
        return false;
      }

      // Actualizar token
      _token = await ServiceLocator().secureTokenManager.getToken();

      // Actualizar usuario si es necesario
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.hasError && userResponse.data != null) {
        _user = userResponse.data;
        _safeNotifyListeners();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Logout optimizado
  Future<void> logout() async {
    _isLoading = true;
    _loading = true;
    _safeNotifyListeners();

    try {
      // Logout en el backend
      await _authService.logout();

      // Limpiar datos locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      _user = null;
      _token = null;
      _isAuthenticated = false;
      _hasCheckedAuth = true;
      _errorMessage = null;
      _error = null;
    } catch (e) {
      _errorMessage = ErrorMessages.fromException(e);
      _error = _errorMessage;
      // Aún así limpiar estado local
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _hasCheckedAuth = true;
    } finally {
      _isLoading = false;
      _loading = false;
      _safeNotifyListeners();
    }
  }

  // ============================
  // MÉTODOS QUE NECESITA EL LOGINSCREEN
  // ============================

  // ✅ Método para verificar token localmente
  bool isTokenValidLocally(String token) {
    return token.isNotEmpty && token != 'null';
  }

  // ✅ Método para obtener usuario caché (de SharedPreferences)
  User? getCachedUser() {
    return _user;
  }

  // ✅ Método para restaurar sesión cacheada
  Future<bool> restoreCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');

      if (storedToken != null && storedToken.isNotEmpty && email != null) {
        // Verificar token localmente
        if (isTokenValidLocally(storedToken)) {
          _token = storedToken;
          _user = User(
            id: 1,
            username: name ?? email.split('@').first,
            email: email,
            password: '',
            roles: [Rol(id: 1, nombre: 'admin')],
            createdAt: DateTime.now(),
          );
          _isAuthenticated = true;
          _errorMessage = null;
          _error = null;

          _safeNotifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================
  // MÉTODOS DE VALIDACIÓN
  // ============================

  String? _validateUsernameOrEmail(String? value) {
    return Validators.validateUsernameOrEmail(value);
  }

  void clearError() {
    if (_errorMessage != null || _error != null) {
      _errorMessage = null;
      _error = null;
      _safeNotifyListeners();
    }
  }

  // ✅ NOTIFICADOR INTELIGENTE (EVITA NOTIFICACIONES INNECESARIAS)
  void _safeNotifyListeners() {
    // ✅ Solo notificar si realmente cambió algo importante
    final userChanged = _user?.id != _previousUser?.id;
    final authChanged = _isAuthenticated != _previousAuthState;
    final loadingChanged = _isLoading != _previousLoadingState;

    if (userChanged || authChanged || loadingChanged) {
      _previousUser = _user;
      _previousAuthState = _isAuthenticated;
      _previousLoadingState = _isLoading;

      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  // ============================
  // MÉTODOS PARA COMPATIBILIDAD
  // ============================

  User get guestUser {
    return User(
      id: 0,
      username: 'Invitado',
      email: 'invitado@ejemplo.com',
      password: '',
      roles: [Rol(id: 2, nombre: 'consult')],
      createdAt: DateTime.now(),
    );
  }

  bool get isAdmin =>
      _user?.roles.any((role) => role.nombre == 'admin') ?? false;

  List<String> get userRoles =>
      _user?.roles.map((r) => r.nombre).toList() ?? [];

  bool hasRole(String roleName) {
    return _user?.roles.any((role) => role.nombre == roleName) ?? false;
  }

  bool hasAnyRole(List<String> roleNames) {
    return _user?.roles.any((role) => roleNames.contains(role.nombre)) ?? false;
  }

  String get displayName {
    if (_user == null) return 'Invitado';
    return _user!.username.isNotEmpty ? _user!.username : _user!.email;
  }

  String get displayEmail {
    if (_user == null) return '';
    return _user!.email;
  }

  bool get isGuest => _user == null;

  // Obtener información de seguridad
  Future<Map<String, dynamic>> getSecurityInfo() async {
    final attempts = await _securityService.getFailedAttempts();
    final remaining = await _securityService.getRemainingAttempts();
    final isLocked = await _securityService.isLockedOut();
    final lockoutTime = await _securityService.getLockoutTime();

    return {
      'failedAttempts': attempts,
      'remainingAttempts': remaining,
      'isLockedOut': isLocked,
      'lockoutTime': lockoutTime,
      'maxAttempts': 5,
    };
  }

  // Helper methods
  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      _isLoading = value;
      _safeNotifyListeners();
    }
  }

  // ============================
  // MÉTODOS DE GESTIÓN DE CACHÉ (OPCIONAL - Mantener si los usas)
  // ============================

  // Future<void> _clearStoredData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('auth_token');
  //   await prefs.remove('user_email');
  //   await prefs.remove('user_name');
  // }

  // Método de registro (si lo necesitas)
  Future<bool> register(String email, String password, String name) async {
    // Esto sería una implementación futura
    return false;
  }

  // ============================
  // MÉTODOS DE GESTIÓN DE CACHÉ (Solo si realmente los necesitas)
  // ============================

  // Método para obtener información detallada del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final supportDir = await getApplicationSupportDirectory();

      int totalSize = 0;
      int itemCount = 0;
      Map<String, int> allDetails = {};
      Map<String, int> categories = {};

      // Directorios a escanear
      final directories = {
        'Documents': appDir,
        'Cache': tempDir,
        'Support': supportDir,
      };

      for (var entry in directories.entries) {
        final dirName = entry.key;
        final directory = entry.value;
        int dirSize = 0;
        int dirItems = 0;

        if (await directory.exists()) {
          final files = await directory.list(recursive: true).toList();

          for (var file in files) {
            if (file is File) {
              try {
                final stat = await file.stat();
                dirSize += stat.size;
                dirItems++;

                final relativePath = path.relative(
                  file.path,
                  from: directory.path,
                );
                allDetails['$dirName/$relativePath'] = stat.size;
              } catch (e) {
                debugPrint('Error accediendo a ${file.path}: $e');
              }
            }
          }

          categories[dirName] = dirSize;
          totalSize += dirSize;
          itemCount += dirItems;
        }
      }

      // Verificar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int prefsSize = 0;

      for (String key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          final size = value.toString().length * 2;
          prefsSize += size;
          allDetails['SharedPrefs/$key'] = size;
        }
      }

      categories['SharedPrefs'] = prefsSize;
      totalSize += prefsSize;
      itemCount += keys.length;

      // Verificar base de datos
      final dbFile = File(path.join(appDir.path, 'app_database.db'));
      int dbSize = 0;
      if (await dbFile.exists()) {
        try {
          final stat = await dbFile.stat();
          dbSize = stat.size;
          allDetails['Database/app_database.db'] = dbSize;
        } catch (e) {
          debugPrint('Error accediendo a base de datos: $e');
        }
      }

      categories['Database'] = dbSize;
      totalSize += dbSize;
      if (dbSize > 0) itemCount++;

      return {
        'total': totalSize,
        'items': itemCount,
        'details': allDetails,
        'categories': categories,
        'directories': directories.keys.toList(),
      };
    } catch (e) {
      return {
        'total': 0,
        'items': 0,
        'details': <String, int>{},
        'categories': {},
        'directories': [],
      };
    }
  }

  // Borrar caché de la aplicación
  Future<bool> clearAppCache() async {
    try {
      // 1. Limpiar directorio cache
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(appDir.path, 'cache'));

      if (await cacheDir.exists()) {
        try {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        } catch (e) {
          debugPrint('Error limpiando directorio cache: $e');
        }
      }

      // 2. Limpiar datos de autenticación
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      // 3. Limpiar estado (pero mantener la app funcional)
      _user = null;
      _token = null;
      _isAuthenticated = false;

      _safeNotifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Borrar TODOS los datos de la aplicación (más agresivo)
  Future<bool> clearAllData() async {
    try {
      // 1. Limpiar todos los directorios
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final supportDir = await getApplicationSupportDirectory();

      final directories = [appDir, tempDir, supportDir];

      for (var directory in directories) {
        if (await directory.exists()) {
          try {
            await directory.delete(recursive: true);
            // Recrear el directorio vacío
            await directory.create(recursive: true);
          } catch (e) {
            debugPrint('✗ Error limpiando ${directory.path}: $e');
          }
        }
      }

      // 2. Eliminar base de datos
      final dbFile = File(path.join(appDir.path, 'app_database.db'));
      if (await dbFile.exists()) {
        try {
          await dbFile.delete();
        } catch (e) {
          debugPrint('✗ Error eliminando base de datos: $e');
        }
      }

      // 3. Borrar TODOS los datos de SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        debugPrint('✗ Error limpiando SharedPreferences: $e');
      }

      // 4. Limpiar caché de imágenes (si usas cached_network_image)
      try {
        final cacheDir = Directory(
          path.join(tempDir.path, 'libCachedImageData'),
        );
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('✗ Error limpiando caché de imágenes: $e');
      }

      // 5. Limpiar estado de la aplicación
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _error = null;

      _safeNotifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
\n```\n
\n## Archivo: lib/providers/department_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/department.dart';
import '../models/department_lite.dart';
import '../utils/error_messages.dart';
import '../services/data/department_repository.dart';

class DepartmentProvider with ChangeNotifier {
  final DepartmentRepository _departmentRepository =
      ServiceLocator().departmentRepository;

  List<Department> _departments = [];
  final List<DepartmentLite> _departmentLites = [];
  final List<DepartmentLite> _allDepartmentLites = [];
  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';

  // NUEVO: Propiedades para paginación
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasMore = true; // NUEVO: Esta propiedad falta
  bool _isLoadingMore = false; // NUEVO
  bool _isSearching = false; // NUEVO
  String _lastSearchQuery = ''; // NUEVO
  final int _pageSize = 20; // NUEVO

  // Propiedades offline existentes
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // Getters existentes
  List<Department> get departments => _departments;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalDepartments => _departments.length;

  // NUEVOS GETTERS PARA PAGINACIÓN
  List<DepartmentLite> get departmentLites => _departmentLites;
  ScrollController get scrollController => _scrollController;
  bool get hasMore => _hasMore; // NUEVO: Agregar este getter
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;

  // Getters offline existentes
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // Cargar departamentos (OFFLINE-FIRST con paginación)
  Future<void> loadDepartments({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';

    // Reiniciar paginación en carga forzada
    if (forceRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _departmentLites.clear();
      _allDepartmentLites.clear();
    }

    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _departmentRepository.getDepartments(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_departmentLites.isNotEmpty || _departments.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;

          // Cargar datos locales paginados
          await _loadLocalDepartmentsPaginated();
        }
      } else {
        _departments = response.data ?? [];

// ORDENAR POR NOMBRE
_departments.sort(
  (a, b) => a.name.toLowerCase().compareTo(
    b.name.toLowerCase(),
  ),
);

_hasLoaded = true;
_isOffline = false;

// Convertir a modelos lite para lista
_departmentLites.clear();
_departmentLites.addAll(
  _departments.map((dept) => DepartmentLite.fromDepartment(dept)),
);

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline y cargarlos
      if (_departmentLites.isNotEmpty || _departments.isNotEmpty) {
        _isOffline = true;
        await _loadLocalDepartmentsPaginated();
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar departamentos locales paginados
  Future<void> _loadLocalDepartmentsPaginated() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final lites = await _departmentRepository
          .getLocalDepartmentsLitePaginated(
            page: _currentPage,
            pageSize: _pageSize,
            searchQuery: _lastSearchQuery,
          );

      if (_currentPage == 0) {
        _departmentLites.clear();
        if (_lastSearchQuery.isEmpty) {
          _allDepartmentLites.clear();
        }
      }

      _departmentLites.addAll(lites);
      if (_lastSearchQuery.isEmpty) {
        _allDepartmentLites.addAll(lites);
      }
      _hasMore = lites.length == _pageSize;
      _currentPage++;
    } catch (e) {
      debugPrint('Error cargando departamentos locales paginados: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // NUEVO: Cargar más datos (infinite scroll)
  Future<void> loadMoreDepartments() async {
    if (_isLoadingMore || !_hasMore || _loading) return;

    await _loadLocalDepartmentsPaginated();
  }

  // NUEVO: Buscar departamentos con debounce
  Future<void> searchDepartments(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    _lastSearchQuery = query.trim();
    _isSearching = normalizedQuery.isNotEmpty;

    // Reiniciar paginación para búsqueda
    _currentPage = 0;
    if (normalizedQuery.isEmpty) {
      // Si la búsqueda está vacía, volver a cargar todos
      clearSearch();
      return;
    }

    final departmentLiteSource = _allDepartmentLites.isNotEmpty
        ? _allDepartmentLites
        : _departmentLites;

    final departmentResults = _departments.isNotEmpty
        ? _departments
              .where(
                (department) =>
                    _matchesDepartmentSearch(department, normalizedQuery),
              )
              .map((department) => DepartmentLite.fromDepartment(department))
              .toList()
        : departmentLiteSource
              .where(
                (department) =>
                    _matchesDepartmentLiteSearch(department, normalizedQuery),
              )
              .toList();

    if (_departments.isNotEmpty || departmentLiteSource.isNotEmpty) {
      _departmentLites
        ..clear()
        ..addAll(departmentResults);
      _hasMore = false;
      notifyListeners();
      return;
    }

    _hasMore = true;
    _departmentLites.clear();
    _loading = true;
    notifyListeners();

    try {
      final results = await _departmentRepository
          .searchDepartmentsLitePaginated(
            query: _lastSearchQuery,
            page: _currentPage,
            pageSize: _pageSize,
          );

      _departmentLites.clear();
      _departmentLites.addAll(results);
      _hasMore = results.length == _pageSize;
      _currentPage++;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Error en búsqueda: $e';
      notifyListeners();
    }
  }

  bool _matchesDepartmentSearch(Department department, String query) {
    return department.name.toLowerCase().contains(query) ||
        department.phone.toLowerCase().contains(query);
  }

  bool _matchesDepartmentLiteSearch(DepartmentLite department, String query) {
    return department.name.toLowerCase().contains(query) ||
        department.phone.toLowerCase().contains(query);
  }

  // NUEVO: Setup scroll controller para infinite scroll
  void setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        loadMoreDepartments();
      }
    });
  }

  // NUEVO: Cleanup scroll controller
  void disposeScrollController() {
    _scrollController.dispose();
  }

  // Obtener departamento por ID (OFFLINE-FIRST)
  Future<Department?> getDepartmentById(int id) async {
    // Primero buscar en lista local
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _departmentRepository.getDepartmentById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _departments.add(response.data!);
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Crear departamento (siempre intenta API primero)
  Future<bool> createDepartment(String name, String phone) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final department = Department(id: 0, name: name, phone: phone);
      final response = await _departmentRepository.createDepartment(department);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir el nuevo departamento
        await loadDepartments(forceRefresh: true);
        _isOffline = false;
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar departamento
  Future<bool> updateDepartment(Department department) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _departmentRepository.updateDepartment(department);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _departments.indexWhere((d) => d.id == department.id);
        if (index != -1) {
          _departments[index] = response.data!;
        }
        // Actualizar en la lista lite si existe
        final liteIndex = _departmentLites.indexWhere(
          (d) => d.id == department.id,
        );
        if (liteIndex != -1) {
          _departmentLites[liteIndex] = DepartmentLite.fromDepartment(
            response.data!,
          );
        }
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Eliminar departamento
  Future<bool> deleteDepartment(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _departmentRepository.deleteDepartment(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _departments.removeWhere((dept) => dept.id == id);
        // Remover de la lista lite
        _departmentLites.removeWhere((dept) => dept.id == id);
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Buscar departamentos (método existente mantenido para compatibilidad)
  Future<List<Department>> searchDepartmentsOld(String query) async {
    try {
      final response = await _departmentRepository.searchDepartments(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _departments.where((dept) {
        return dept.name.toLowerCase().contains(query.toLowerCase()) ||
            dept.phone.contains(query);
      }).toList();
    } catch (e) {
      return _departments.where((dept) {
        return dept.name.toLowerCase().contains(query.toLowerCase()) ||
            dept.phone.contains(query);
      }).toList();
    }
  }

  // NUEVO: Actualizar estadísticas locales
  Future<void> _updateLocalStats() async {
    try {
      final stats = await _departmentRepository.getLocalStats();
      _localDataCount = stats['totalDepartments'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      debugPrint(
        'Error actualizando estadísticas locales de departamentos: $e',
      );
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncDepartments() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _departmentRepository.syncDepartments();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadDepartments(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar departamentos';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refreshDepartments() async {
    await loadDepartments(forceRefresh: true);
  }

  void clearSearch() {
    _lastSearchQuery = '';
    _isSearching = false;
    _currentPage = 0;
    _hasMore = _departmentLites.length > _pageSize;

    if (_departments.isNotEmpty) {
      _departmentLites
        ..clear()
        ..addAll(
          _departments.map((dept) => DepartmentLite.fromDepartment(dept)),
        );
      _allDepartmentLites
        ..clear()
        ..addAll(_departmentLites);
      _hasMore = false;
    } else if (_allDepartmentLites.isNotEmpty) {
      _departmentLites
        ..clear()
        ..addAll(_allDepartmentLites);
      _hasMore = false;
    }

    notifyListeners();
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadDepartments();
    }

    // Setup scroll controller
    setupScrollController();

    // Actualizar estadísticas
    await _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _departments.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'hasPhone': _departments.where((d) => d.phone.isNotEmpty).length,
    };
  }

  @override
  void dispose() {
    disposeScrollController();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/providers/efemeride_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/data/efemeride_repository.dart';
import '../services/service_locator.dart';
import '../models/efemeride.dart';
import '../utils/error_messages.dart';

class EfemerideProvider with ChangeNotifier {
  final EfemerideRepository _efemerideRepository =
      ServiceLocator().efemerideRepository;

  List<Efemeride> _efemerides = [];
  List<Efemeride> _todayEfemerides = [];
  List<Efemeride> _upcomingEfemerides = [];
  final Map<int, List<Efemeride>> _efemeridesByMonth = {};

  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';

  // NUEVAS PROPIEDADES PARA OFFLINE
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // Getters
  List<Efemeride> get efemerides => _efemerides;
  List<Efemeride> get todayEfemerides => _todayEfemerides;
  List<Efemeride> get upcomingEfemerides => _upcomingEfemerides;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalEfemerides => _efemerides.length;

  // NUEVOS GETTERS PARA OFFLINE
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // ============ MÉTODOS PRINCIPALES (OFFLINE-FIRST) ============

  // Cargar todas las efemérides
  Future<void> loadEfemerides({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _efemerideRepository.getEfemerides(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_efemerides.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;
        }
      } else {
        _efemerides = response.data ?? [];
        _hasLoaded = true;
        _isOffline = false;

        // Actualizar listas derivadas
        _updateDerivedLists();

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline
      if (_efemerides.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // NUEVO: Actualizar listas derivadas
  void _updateDerivedLists() {
    final now = DateTime.now();

    // Efemérides de hoy
    _todayEfemerides = _efemerides.where((efemeride) {
      return efemeride.isToday;
    }).toList();

    // Efemérides próximas (próximos 7 días)
    _upcomingEfemerides = _efemerides.where((efemeride) {
      final difference = efemeride.fecha.difference(now).inDays;
      return difference >= 0 && difference <= 7;
    }).toList();

    // Organizar por mes
    _efemeridesByMonth.clear();
    for (final efemeride in _efemerides) {
      final monthKey = efemeride.fecha.month;
      if (!_efemeridesByMonth.containsKey(monthKey)) {
        _efemeridesByMonth[monthKey] = [];
      }
      _efemeridesByMonth[monthKey]!.add(efemeride);
    }
  }

  // NUEVO: Actualizar estadísticas locales
  // Corregir en el método _updateLocalStats() del provider:
  void _updateLocalStats() async {
    try {
      final stats = await _efemerideRepository.getLocalStats();
      _localDataCount = stats['totalEfemerides'] as int;

      final lastSyncString = stats['lastSyncFormatted'] as String?;
      if (lastSyncString != null && lastSyncString != 'Nunca') {
        try {
          _lastSyncDate = DateTime.parse(lastSyncString);
        } catch (e) {
          _lastSyncDate = null;
        }
      } else {
        _lastSyncDate = null;
      }
    } catch (e) {
      '';
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncEfemerides() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _efemerideRepository.syncEfemerides();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadEfemerides(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar efemérides';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ MÉTODOS DE CONSULTA ============

  // Obtener efemérides por mes
  List<Efemeride> getEfemeridesByMonth(int month) {
    // Primero buscar en cache local
    if (_efemeridesByMonth.containsKey(month)) {
      return _efemeridesByMonth[month]!;
    }

    // Si no está en cache, calcular
    final monthEfemerides = _efemerides
        .where((efemeride) => efemeride.fecha.month == month)
        .toList();

    _efemeridesByMonth[month] = monthEfemerides;
    return monthEfemerides;
  }

  // Obtener efemérides por mes (con carga remota si es necesario)
  Future<List<Efemeride>> loadEfemeridesByMonth(int month) async {
    try {
      final response = await _efemerideRepository.getEfemeridesByMonth(month);

      if (!response.hasError && response.data != null) {
        // Actualizar lista principal con nuevos datos
        _updateEfemerideList(response.data!);
        return response.data!;
      }

      // Fallback a datos locales
      return getEfemeridesByMonth(month);
    } catch (e) {
      return getEfemeridesByMonth(month);
    }
  }

  // Obtener efemérides por fecha
  Future<List<Efemeride>> getEfemeridesByDate(DateTime date) async {
    try {
      final response = await _efemerideRepository.getEfemeridesByDate(date);

      if (!response.hasError && response.data != null) {
        // Actualizar lista principal con nuevos datos
        _updateEfemerideList(response.data!);
        return response.data!;
      }

      // Fallback a datos locales
      return _efemerides.where((efemeride) {
        return efemeride.isSameDate(date);
      }).toList();
    } catch (e) {
      return _efemerides.where((efemeride) {
        return efemeride.isSameDate(date);
      }).toList();
    }
  }

  // Cargar efemérides de hoy (con soporte offline)
  Future<void> loadTodayEfemerides() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.getTodayEfemerides();

      _loading = false;

      if (response.hasError) {
        // Usar datos locales si hay error
        if (_efemerides.isNotEmpty) {
          _todayEfemerides = _efemerides.where((e) => e.isToday).toList();
          _isOffline = true;
        } else {
          _todayEfemerides = [];
        }
      } else {
        _todayEfemerides = response.data ?? [];
        _isOffline = false;

        // Actualizar lista principal
        _updateEfemerideList(_todayEfemerides);
      }
      notifyListeners();
    } catch (e) {
      _loading = false;

      // Fallback a datos locales
      _todayEfemerides = _efemerides.where((e) => e.isToday).toList();
      if (_todayEfemerides.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar efemérides próximas
  Future<void> loadUpcomingEfemerides(int days) async {
    try {
      final response = await _efemerideRepository.getUpcomingEfemerides(days);

      if (!response.hasError && response.data != null) {
        _upcomingEfemerides = response.data!;
        _updateEfemerideList(_upcomingEfemerides);
      }
    } catch (e) {
      // Fallback a cálculo local
      final now = DateTime.now();
      _upcomingEfemerides = _efemerides.where((efemeride) {
        final difference = efemeride.fecha.difference(now).inDays;
        return difference >= 0 && difference <= days;
      }).toList();
    }
  }

  // ============ OPERACIONES CRUD ============

  // Crear efeméride
  Future<bool> createEfemeride(
    DateTime fecha,
    String dato,
    String detalle,
  ) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final efemeride = Efemeride(
        id: 0,
        fecha: fecha,
        dato: dato,
        detalle: detalle,
      );

      final response = await _efemerideRepository.createEfemeride(efemeride);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir la nueva efeméride
        await loadEfemerides(forceRefresh: true);
        _isOffline = false;
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar efeméride
  Future<bool> updateEfemeride(Efemeride efemeride) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.updateEfemeride(efemeride);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _efemerides.indexWhere((e) => e.id == efemeride.id);
        if (index != -1) {
          _efemerides[index] = response.data!;
          _updateDerivedLists();
        }
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Eliminar efeméride
  Future<bool> deleteEfemeride(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.deleteEfemeride(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _efemerides.removeWhere((e) => e.id == id);
        _updateDerivedLists();
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // ============ MÉTODOS ADICIONALES ============

  // Buscar efemérides
  Future<List<Efemeride>> searchEfemerides(String query) async {
    try {
      final response = await _efemerideRepository.searchEfemerides(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _efemerides.where((efemeride) {
        return efemeride.dato.toLowerCase().contains(query.toLowerCase()) ||
            efemeride.detalle.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      return _efemerides.where((efemeride) {
        return efemeride.dato.toLowerCase().contains(query.toLowerCase()) ||
            efemeride.detalle.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // Obtener estadísticas
  // En EfemerideProvider, simplifica el método:
  Future<Map<String, dynamic>> getEfemerideStats() async {
    try {
      // Usar el repositorio que ahora tiene el método implementado
      return await _efemerideRepository.getEfemerideStats();
    } catch (e) {
      return {
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
        'hoy': 0,
        'last_sync': 'Error',
        'is_offline': true,
      };
    }
  }

  // ============ MÉTODOS DE UTILIDAD ============

  // NUEVO: Actualizar lista principal manteniendo unicidad
  void _updateEfemerideList(List<Efemeride> newEfemerides) {
    final Map<int, Efemeride> efemerideMap = {};

    // Primero agregar existentes
    for (final efemeride in _efemerides) {
      efemerideMap[efemeride.id] = efemeride;
    }

    // Luego actualizar/agregar nuevas
    for (final efemeride in newEfemerides) {
      efemerideMap[efemeride.id] = efemeride;
    }

    // Convertir de nuevo a lista y ordenar por fecha
    _efemerides = efemerideMap.values.toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    _updateDerivedLists();
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refreshEfemerides() async {
    await loadEfemerides(forceRefresh: true);
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadEfemerides();
    }

    // Cargar efemérides de hoy
    await loadTodayEfemerides();

    // Cargar efemérides próximas
    await loadUpcomingEfemerides(7);

    // Actualizar estadísticas
    _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas del provider
  Map<String, dynamic> getStatistics() {
    return {
      'total': _efemerides.length,
      'today': _todayEfemerides.length,
      'upcoming': _upcomingEfemerides.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'byMonth': _efemeridesByMonth.keys.length,
    };
  }

  // NUEVO: Obtener efeméride por ID
  Future<Efemeride?> getEfemerideById(int id) async {
    // Primero buscar localmente
    try {
      return _efemerides.firstWhere((efemeride) => efemeride.id == id);
    } catch (e) {
      // Si no está local, cargar individualmente
      final response = await _efemerideRepository.getEfemerideById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local
        _efemerides.add(response.data!);
        _efemerides.sort((a, b) => a.fecha.compareTo(b.fecha));
        _updateDerivedLists();
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }
}
\n```\n
\n## Archivo: lib/providers/local_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/local.dart';
import '../models/local_lite.dart'; // NUEVO
import '../utils/error_messages.dart';
import '../services/data/local_repository.dart';

class LocalProvider with ChangeNotifier {
  final LocalRepository _localRepository = ServiceLocator().localRepository;

  List<Local> _locals = [];
  final List<LocalLite> _localLites = []; // NUEVO
  final List<LocalLite> _allLocalLites = [];
  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';

  // NUEVO: Propiedades para paginación
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasMore = true; // NUEVO: Esta propiedad falta
  bool _isLoadingMore = false; // NUEVO
  bool _isSearching = false; // NUEVO
  String _lastSearchQuery = ''; // NUEVO
  final int _pageSize = 20; // NUEVO

  // Propiedades offline existentes
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // Getters existentes
  List<Local> get locals => _locals;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalLocals => _locals.length;

  // NUEVOS GETTERS PARA PAGINACIÓN
  List<LocalLite> get localLites => _localLites;
  ScrollController get scrollController => _scrollController;
  bool get hasMore => _hasMore; // NUEVO: Agregar este getter
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;

  // Getters offline existentes
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // Cargar locales (OFFLINE-FIRST con paginación)
  Future<void> loadLocals({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';

    // Reiniciar paginación en carga forzada
    if (forceRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _localLites.clear();
      _allLocalLites.clear();
    }

    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _localRepository.getLocals(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_localLites.isNotEmpty || _locals.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;

          // Cargar datos locales paginados
          await _loadLocalLocalsPaginated();
        }
      } else {
        _locals = response.data ?? [];

        _locals.sort(
  (a, b) => a.name.toLowerCase().compareTo(
    b.name.toLowerCase(),
  ),
);

        _hasLoaded = true;
        _isOffline = false;

        // Convertir a modelos lite para lista
        _localLites.clear();
        _localLites.addAll(_locals.map((local) => LocalLite.fromLocal(local)));
        // _allLocalLites
        //   ..clear()
        //   ..addAll(_localLites);

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline y cargarlos
      if (_localLites.isNotEmpty || _locals.isNotEmpty) {
        _isOffline = true;
        await _loadLocalLocalsPaginated();
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar locales locales paginados
  Future<void> _loadLocalLocalsPaginated() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final lites = await _localRepository.getLocalLocalsLitePaginated(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _lastSearchQuery,
      );

      if (_currentPage == 0) {
        _localLites.clear();
        if (_lastSearchQuery.isEmpty) {
          _allLocalLites.clear();
        }
      }

      _localLites.addAll(lites);
      if (_lastSearchQuery.isEmpty) {
        _allLocalLites.addAll(lites);
      }
      _hasMore = lites.length == _pageSize;
      _currentPage++;
    } catch (e) {
      debugPrint('Error cargando locales locales paginados: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // NUEVO: Cargar más datos (infinite scroll)
  Future<void> loadMoreLocals() async {
    if (_isLoadingMore || !_hasMore || _loading) return;

    await _loadLocalLocalsPaginated();
  }

  // NUEVO: Buscar locales con debounce
  Future<void> searchLocals(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    _lastSearchQuery = query.trim();
    _isSearching = normalizedQuery.isNotEmpty;

    // Reiniciar paginación para búsqueda
    _currentPage = 0;
    if (normalizedQuery.isEmpty) {
      // Si la búsqueda está vacía, volver a cargar todos
      clearSearch();
      return;
    }

    final localLiteSource = _allLocalLites.isNotEmpty
        ? _allLocalLites
        : _localLites;

    final localResults = _locals.isNotEmpty
        ? _locals
              .where((local) => _matchesLocalSearch(local, normalizedQuery))
              .map((local) => LocalLite.fromLocal(local))
              .toList()
        : localLiteSource
              .where((local) => _matchesLocalLiteSearch(local, normalizedQuery))
              .toList();

    if (_locals.isNotEmpty || localLiteSource.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(localResults);
      _hasMore = false;
      notifyListeners();
      return;
    }

    _hasMore = true;
    _localLites.clear();
    _loading = true;
    notifyListeners();

    try {
      final results = await _localRepository.searchLocalsLitePaginated(
        query: _lastSearchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _localLites.clear();
      _localLites.addAll(results);
      _hasMore = results.length == _pageSize;
      _currentPage++;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Error en búsqueda: $e';
      notifyListeners();
    }
  }

  bool _matchesLocalSearch(Local local, String query) {
    return local.name.toLowerCase().contains(query) ||
        local.phone.toLowerCase().contains(query);
  }

  bool _matchesLocalLiteSearch(LocalLite local, String query) {
    return local.name.toLowerCase().contains(query) ||
        local.phone.toLowerCase().contains(query);
  }

  // NUEVO: Setup scroll controller para infinite scroll
  void setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        loadMoreLocals();
      }
    });
  }

  // NUEVO: Cleanup scroll controller
  void disposeScrollController() {
    _scrollController.dispose();
  }

  // Obtener local por ID (OFFLINE-FIRST)
  Future<Local?> getLocalById(int id) async {
    // Primero buscar en lista local
    try {
      return _locals.firstWhere((local) => local.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _localRepository.getLocalById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _locals.add(response.data!);
        // Agregar también a la lista lite
        _localLites.add(LocalLite.fromLocal(response.data!));
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Crear local (siempre intenta API primero)
  Future<bool> createLocal(String name, String phone) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final local = Local(id: 0, name: name, phone: phone);
      final response = await _localRepository.createLocal(local);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir el nuevo local
        await loadLocals(forceRefresh: true);
        _isOffline = false;
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar local
  Future<bool> updateLocal(Local local) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _localRepository.updateLocal(local);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _locals.indexWhere((l) => l.id == local.id);
        if (index != -1) {
          _locals[index] = response.data!;
        }
        // Actualizar en la lista lite si existe
        final liteIndex = _localLites.indexWhere((l) => l.id == local.id);
        if (liteIndex != -1) {
          _localLites[liteIndex] = LocalLite.fromLocal(response.data!);
        }
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Eliminar local
  Future<bool> deleteLocal(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _localRepository.deleteLocal(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _locals.removeWhere((local) => local.id == id);
        // Remover de la lista lite
        _localLites.removeWhere((local) => local.id == id);
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Buscar locales (método existente mantenido para compatibilidad)
  Future<List<Local>> searchLocalsOld(String query) async {
    try {
      final response = await _localRepository.searchLocals(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _locals.where((local) {
        return local.name.toLowerCase().contains(query.toLowerCase()) ||
            local.phone.contains(query);
      }).toList();
    } catch (e) {
      return _locals.where((local) {
        return local.name.toLowerCase().contains(query.toLowerCase()) ||
            local.phone.contains(query);
      }).toList();
    }
  }

  // NUEVO: Actualizar estadísticas locales
  Future<void> _updateLocalStats() async {
    try {
      final stats = await _localRepository.getLocalStats();
      _localDataCount = stats['totalLocals'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      ''; // Silenciar error
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncLocals() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _localRepository.syncLocals();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadLocals(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar locales';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refreshLocals() async {
    await loadLocals(forceRefresh: true);
  }

  void clearSearch() {
    _lastSearchQuery = '';
    _isSearching = false;
    _currentPage = 0;
    _hasMore = _localLites.length > _pageSize;

    if (_locals.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(_locals.map((local) => LocalLite.fromLocal(local)));
      _allLocalLites
        ..clear()
        ..addAll(_localLites);
      _hasMore = false;
    } else if (_allLocalLites.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(_allLocalLites);
      _hasMore = false;
    }

    notifyListeners();
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadLocals();
    }

    // Setup scroll controller
    setupScrollController();

    // Actualizar estadísticas
    await _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _locals.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'hasPhone': _locals.where((l) => l.phone.isNotEmpty).length,
    };
  }

  @override
  void dispose() {
    disposeScrollController();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/providers/update_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/update_info.dart';

class UpdateProvider with ChangeNotifier {
  UpdateInfo? _pendingUpdate;
  bool _isChecking = false;

  UpdateInfo? get pendingUpdate => _pendingUpdate;
  bool get isChecking => _isChecking;

  Future<void> checkForUpdates({bool force = false}) async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      final updateService = ServiceLocator().updateService;
      final updateInfo = await updateService.checkUpdates(forceCheck: force);

      if (updateInfo != null) {
        _pendingUpdate = updateInfo;
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> processNotificationTap(
    BuildContext context,
    String version,
  ) async {
    // Verificar si hay actualización pendiente
    if (_pendingUpdate == null) {
      await checkForUpdates(force: true);
    }

    // Si hay actualización, mostrar diálogo
    if (_pendingUpdate != null && context.mounted) {
      final updateService = ServiceLocator().updateService;
      updateService.showUpdateNotification(context, _pendingUpdate!);
    }
  }

  void clearPendingUpdate() {
    _pendingUpdate = null;
    notifyListeners();
  }
}
\n```\n
\n## Archivo: lib/providers/user_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/data/user_repository.dart';
import '../services/service_locator.dart';
import '../models/user.dart';
import '../models/rol.dart';
import '../models/create_usuario_dto.dart';
import '../utils/error_messages.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository = ServiceLocator().userRepository;

  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _loading = false;
  bool _syncing = false;
  String _error = '';
  bool _creatingUser = false;
  Rol _selectedRol = Rol.consult;
  String _searchQuery = '';

  // Getters
  List<User> get users => _users;
  List<User> get filteredUsers => _filteredUsers;
  bool get loading => _loading;
  bool get syncing => _syncing;
  String get error => _error;
  bool get creatingUser => _creatingUser;
  Rol get selectedRol => _selectedRol;
  String get searchQuery => _searchQuery;

  // Lista de roles disponibles
  List<Rol> get availableRoles => [Rol.admin, Rol.consult];

  // Setters
  void setSelectedRol(Rol rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterUsers();
    notifyListeners();
  }

  // Filtrar usuarios por búsqueda
  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _users.where((user) {
        return user.username.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Cargar usuarios (con soporte offline)
  Future<void> loadUsers({bool forceRefresh = false}) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.getUsers(
        forceRefresh: forceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;
      } else {
        _users = response.data ?? [];
        _filterUsers(); // Aplicar filtro actual
      }

      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
    }
  }

  // Buscar usuarios (con soporte offline)
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadUsers();
      return;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.searchUsers(query);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;
      } else {
        _users = response.data ?? [];
        _filteredUsers = List.from(_users);
      }

      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
    }
  }

  // Crear usuario (solo online)
  Future<bool> createUser({
    required String nombreUsuario,
    required String email,
    required String password,
    required Rol rol,
  }) async {
    _creatingUser = true;
    _error = '';
    notifyListeners();

    try {
      // Crear DTO
      final usuarioDto = CreateUsuarioDto(
        nombreUsuario: nombreUsuario,
        email: email,
        password: password,
        rolNombre: rol.nombre,
      );

      final response = await _userRepository.createUserOnline(usuarioDto);

      _creatingUser = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Agregar nuevo usuario a la lista
        if (response.data != null) {
          _users.add(response.data!);
          _filterUsers();
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _creatingUser = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar usuario (solo online)
  Future<bool> updateUser(User user) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.updateUserOnline(user);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar usuario en la lista
        if (response.data != null) {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = response.data!;
            _filterUsers();
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Obtener usuario por ID (con soporte offline)
  Future<User?> getUserById(int id) async {
    try {
      final response = await _userRepository.getUserByIdLocal(id);
      if (!response.hasError) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sincronizar usuarios con backend
  Future<bool> syncUsers() async {
    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _userRepository.syncUsers();

      _syncing = false;

      if (success) {
        // Recargar usuarios después de sincronizar
        await loadUsers();
      } else {
        _error = 'No se pudo sincronizar con el servidor';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Obtener estadísticas (con soporte offline)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return await _userRepository.getUserStats();
    } catch (e) {
      return {
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      };
    }
  }

  // Obtener estadísticas locales
  Future<Map<String, dynamic>> getLocalStats() async {
    try {
      return await _userRepository.getLocalStats();
    } catch (e) {
      return {
        'totalUsers': 0,
        'lastSyncFormatted': 'Nunca',
        'hasSession': false,
      };
    }
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar
  Future<void> refreshUsers() async {
    await loadUsers(forceRefresh: true);
  }

  // Obtener estadísticas por rol
  Map<String, int> getRoleStats() {
    final stats = <String, int>{'admin': 0, 'consult': 0};

    for (final user in _users) {
      if (user.isAdmin) {
        stats['admin'] = stats['admin']! + 1;
      }
      if (user.isConsult) {
        stats['consult'] = stats['consult']! + 1;
      }
    }

    return stats;
  }

  // Verificar si hay datos locales
  bool get hasLocalData => _users.isNotEmpty;

  // Limpiar datos (para logout)
  void clearData() {
    _users.clear();
    _filteredUsers.clear();
    _searchQuery = '';
    _error = '';
    notifyListeners();
  }
}
\n```\n
\n## Archivo: lib/providers/worker_provider.dart\n```
import 'package:flutter/material.dart';
import '../services/data/worker_repository.dart';
import '../services/service_locator.dart';
import '../models/worker.dart';
import '../models/worker_lite.dart';
import '../utils/error_messages.dart';

class WorkerProvider with ChangeNotifier {
  final WorkerRepository _workerRepository = ServiceLocator().workerRepository;

  // DATOS PAGINADOS
  List<Worker> _allWorkers = [];
  List<WorkerLite> _allWorkersLite = []; // Versión ligera para listas
  List<WorkerLite> _filteredWorkersLite = [];

  // ESTADO DE PAGINACIÓN
  int _currentPage = 0;
  final int _pageSize = 30; // Cantidad por página
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // ESTADO GENERAL
  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';
  String _searchQuery = '';

  // 🔹 NUEVO: filtro por departamento
  int? _filterDepartmentId;

  // OFFLINE
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // GETTERS
  List<Worker> get workers => _allWorkers;

  // 🔹 NUEVO: helper para saber si hay filtros activos
  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || _filterDepartmentId != null;

  // Para UI - usa WorkerLite cuando sea posible
  // 🔹 CAMBIADO: usa _hasActiveFilters en vez de "isEmpty" (bug si filtro da 0)
  List<WorkerLite> get workersLite =>
      _hasActiveFilters ? _filteredWorkersLite : _allWorkersLite;

  List<WorkerLite> get allWorkersLite => _allWorkersLite;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalWorkers => _allWorkers.length;
  int get filteredCount => _filteredWorkersLite.length;

  // 🔹 NUEVO: getter público del filtro por departamento
  int? get filterDepartmentId => _filterDepartmentId;

  // PAGINACIÓN
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get pageSize => _pageSize;
  int get loadedCount => _allWorkersLite.length;

  // OFFLINE
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // ============ MÉTODOS PRINCIPALES (PAGINACIÓN) ============

  // Cargar primera página
  Future<void> loadWorkers({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      // Cargar todos los trabajadores de una vez (sin paginación backend)
      final response = await _workerRepository.getWorkers(
        forceRefresh: forceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_allWorkers.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;
        }
      } else {
        _allWorkers = response.data ?? [];

        // Convertir a WorkerLite para listas
        _allWorkersLite = _allWorkers
            .map((w) => WorkerLite.fromWorker(w))
            .toList();

        _hasLoaded = true;
        _isOffline = false;

        // 🔹 CAMBIADO: aplicar filtros combinados (búsqueda + departamento)
        _applyFilters();

        // Actualizar estadísticas locales
        await _updateLocalStats();

        // Calcular si hay más datos (para paginación cliente)
        _hasMore = _allWorkersLite.length > _pageSize;
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline
      if (_allWorkers.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // Cargar más datos (paginación del lado cliente)
  Future<bool> loadMoreWorkers() async {
    if (_isLoadingMore || !_hasMore || _allWorkersLite.isEmpty) {
      return false;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Simular delay para paginación (opcional)
      await Future.delayed(const Duration(milliseconds: 300));

      _currentPage++;

      // En paginación cliente, ya tenemos todos los datos
      // Simplemente actualizamos el estado
      final totalItems = _allWorkersLite.length;
      final loadedItems = (_currentPage + 1) * _pageSize;

      _hasMore = loadedItems < totalItems;

      _isLoadingMore = false;

      // 🔹 CAMBIADO: recalcular con filtros combinados
      if (_hasActiveFilters) {
        _applyFilters();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isLoadingMore = false;
      _hasMore = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener trabajadores visibles actualmente (paginados)
  // 🔹 CAMBIADO: usa _hasActiveFilters y la fuente correcta
  List<WorkerLite> get visibleWorkers {
    if (_allWorkersLite.isEmpty) return [];

    final workersToShow = _hasActiveFilters
        ? _filteredWorkersLite
        : _allWorkersLite;

    final endIndex = _hasMore
        ? (_currentPage + 1) * _pageSize
        : workersToShow.length;

    return workersToShow.sublist(
      0,
      endIndex > workersToShow.length ? workersToShow.length : endIndex,
    );
  }

  // Buscar trabajadores (optimizada para paginación)
  void searchWorkers(String query) {
    _searchQuery = query;
    _currentPage = 0; // Resetear a primera página al buscar
    _applyFilters(); // 🔹 CAMBIADO
    notifyListeners();
  }

  // 🔹 NUEVO: filtro real por departamento
  void filterByDepartment(int? departmentId) {
    if (_filterDepartmentId == departmentId) return;

    _filterDepartmentId = departmentId;
    _currentPage = 0; // Resetear paginación al cambiar filtro
    _applyFilters();
    notifyListeners();
  }

  // 🔹 NUEVO: aplica búsqueda + filtro de departamento combinados
  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    final deptId = _filterDepartmentId;

    // Sin filtros → todos
    if (query.isEmpty && deptId == null) {
      _filteredWorkersLite = _allWorkersLite;
      _hasMore = _allWorkersLite.length > _pageSize;
      return;
    }

    final filtered = _allWorkersLite.where((worker) {
      // Filtro por departamento
      if (deptId != null && worker.departamentoID != deptId) {
        return false;
      }
      // Filtro por texto (nombre, carnet, teléfono)
      if (query.isNotEmpty) {
        final fullName = worker.fullName.toLowerCase();
        final carnet = worker.carnetID.toLowerCase();
        final phone = worker.phone.toLowerCase();
        if (!fullName.contains(query) &&
            !carnet.contains(query) &&
            !phone.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    _filteredWorkersLite = filtered;
    _hasMore = filtered.length > _pageSize;
  }

  // Obtener trabajador completo por ID
  Future<Worker?> getWorkerById(int id) async {
    // Buscar en lista local
    try {
      return _allWorkers.firstWhere((worker) => worker.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _workerRepository.getWorkerById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _allWorkers.add(response.data!);
        _allWorkersLite.add(WorkerLite.fromWorker(response.data!));
        _applyFilters(); // 🔹 CAMBIADO
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Obtener WorkerLite por ID (más rápido para listas)
  WorkerLite? getWorkerLiteById(int id) {
    try {
      return _allWorkersLite.firstWhere((worker) => worker.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============ MÉTODOS DE OFFLINE (MANTENER) ============

  Future<void> _updateLocalStats() async {
    try {
      final stats = await _workerRepository.getLocalStats();
      _localDataCount = stats['totalWorkers'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      debugPrint('Error actualizando estadísticas locales: $e');
    }
  }

  Future<bool> syncWorkers() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _workerRepository.syncWorkers();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadWorkers(forceRefresh: true);
        _isOffline = false;
        _showSuccessMessage('✅ Datos sincronizados correctamente');
      } else {
        _error = 'Error al sincronizar datos';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ CRUD OPERATIONS ============

  Future<bool> createWorker(Worker worker) async {
    debugPrint('[WorkerProvider][CREATE] Requested: ${_workerLog(worker)}');

    if (_loading) {
      debugPrint(
        '[WorkerProvider][CREATE] Ignored because provider is loading',
      );
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();
    debugPrint('[WorkerProvider][CREATE] Calling repository');

    try {
      final response = await _workerRepository.createWorker(worker);
      _loading = false;
      debugPrint(
        '[WorkerProvider][CREATE] Repository response hasError=${response.hasError} status=${response.statusCode} error="${response.error}" technical="${response.technicalError}" data=${response.data != null ? _workerLog(response.data!) : null}',
      );

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        debugPrint('[WorkerProvider][CREATE] Failed: $_error');
        notifyListeners();
        return false;
      } else {
        _allWorkers.add(response.data!);
        _allWorkersLite.add(WorkerLite.fromWorker(response.data!));
        _applyFilters(); // 🔹 CAMBIADO
        _isOffline = false;
        debugPrint(
          '[WorkerProvider][CREATE] Success. totalWorkers=${_allWorkers.length} visible=${visibleWorkers.length}',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      debugPrint('[WorkerProvider][CREATE] Exception: $e parsedError=$_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorker(Worker worker) async {
    debugPrint('[WorkerProvider][EDIT] Requested: ${_workerLog(worker)}');

    if (_loading) {
      debugPrint('[WorkerProvider][EDIT] Ignored because provider is loading');
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();
    debugPrint('[WorkerProvider][EDIT] Calling repository');

    try {
      final response = await _workerRepository.updateWorker(worker);
      _loading = false;
      debugPrint(
        '[WorkerProvider][EDIT] Repository response hasError=${response.hasError} status=${response.statusCode} error="${response.error}" technical="${response.technicalError}" data=${response.data != null ? _workerLog(response.data!) : null}',
      );

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        debugPrint('[WorkerProvider][EDIT] Failed: $_error');
        notifyListeners();
        return false;
      } else {
        final index = _allWorkers.indexWhere((w) => w.id == worker.id);
        if (index != -1) {
          _allWorkers[index] = response.data!;
          _allWorkersLite[index] = WorkerLite.fromWorker(response.data!);
          _applyFilters(); // 🔹 CAMBIADO
          debugPrint('[WorkerProvider][EDIT] Updated local index=$index');
        } else {
          debugPrint(
            '[WorkerProvider][EDIT] Warning: worker id=${worker.id} was not found in local list',
          );
        }
        _isOffline = false;
        debugPrint(
          '[WorkerProvider][EDIT] Success. totalWorkers=${_allWorkers.length} visible=${visibleWorkers.length}',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      debugPrint('[WorkerProvider][EDIT] Exception: $e parsedError=$_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorker(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _workerRepository.deleteWorker(id);
      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        _allWorkers.removeWhere((w) => w.id == id);
        _allWorkersLite.removeWhere((w) => w.id == id);
        _applyFilters(); // 🔹 CAMBIADO
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // ============ UTILIDADES ============

  // 🔹 CAMBIADO: respeta el filtro de departamento activo
  void clearSearch() {
    _searchQuery = '';
    _currentPage = 0;
    _applyFilters();
    notifyListeners();
  }

  // 🔹 NUEVO: limpia búsqueda Y filtro de departamento
  void clearAllFilters() {
    _searchQuery = '';
    _filterDepartmentId = null;
    _currentPage = 0;
    _applyFilters();
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshWorkers() async {
    await loadWorkers(forceRefresh: true);
  }

  // Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadWorkers();
    }
    await _updateLocalStats();
  }

  // Resetear paginación
  void resetPagination() {
    _currentPage = 0;
    _hasMore = _allWorkersLite.length > _pageSize;
    notifyListeners();
  }

  // Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    final withDepartment = _allWorkers.where((w) => w.hasDepartment).length;
    final withLocal = _allWorkers.where((w) => w.hasLocal).length;
    final withPhone = _allWorkers.where((w) => w.hasPhone).length;
    final birthdayThisMonth = _allWorkers
        .where((w) => w.hasBirthdayThisMonth)
        .length;
    final birthdayToday = _allWorkers.where((w) => w.hasBirthdayToday).length;

    return {
      'total': _allWorkers.length,
      'loaded': _allWorkersLite.length,
      'visible': visibleWorkers.length,
      'withDepartment': withDepartment,
      'withLocal': withLocal,
      'withPhone': withPhone,
      'birthdayThisMonth': birthdayThisMonth,
      'birthdayToday': birthdayToday,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'currentPage': _currentPage,
      'hasMore': _hasMore,
      // 🔹 NUEVO: estado de filtros
      'filteredCount': _hasActiveFilters
          ? _filteredWorkersLite.length
          : _allWorkersLite.length,
      'activeFilterDept': _filterDepartmentId,
    };
  }

  void _showSuccessMessage(String message) {
    debugPrint('Success: $message');
  }

  String _workerLog(Worker worker) {
    return {
      'id': worker.id,
      'nombre': worker.name,
      'apellido': worker.lastName,
      'carnetIdentidad': worker.carnetID,
      'numeroCelular': worker.phone,
      'direccion': worker.address,
      'fechaCumpleanno': worker.fechaCumpleannos,
      'departamentoId': worker.departamentoID,
      'localId': worker.localId,
    }.toString();
  }

  // Obtener trabajadores por departamento (paginados)
  List<WorkerLite> getWorkersByDepartmentLite(int departmentId) {
    final filtered = _allWorkersLite
        .where((worker) => worker.departamentoID == departmentId)
        .toList();

    final endIndex = (_currentPage + 1) * _pageSize;
    return endIndex > filtered.length
        ? filtered
        : filtered.sublist(0, endIndex);
  }

  // Obtener trabajadores por local (paginados)
  List<WorkerLite> getWorkersByLocalLite(int localId) {
    final filtered = _allWorkersLite
        .where((worker) => worker.localId == localId)
        .toList();

    final endIndex = (_currentPage + 1) * _pageSize;
    return endIndex > filtered.length
        ? filtered
        : filtered.sublist(0, endIndex);
  }
}
\n```\n
\n## Archivo: lib/screen/auth/login_screen.dart\n```
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/dialog_error_handler.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/responsive_button.dart';
import '../../widgets/shared/responsive_container.dart';
import '../../widgets/shared/responsive_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _checkingCachedSession = true;
  User? _cachedUser;

  @override
  void initState() {
    super.initState();
    _checkCachedSession();
  }

  // Verificar si hay sesión cacheada
  Future<void> _checkCachedSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Verificar sesión cacheada usando el método getCachedUser
      final cachedUser = authProvider.getCachedUser();

      setState(() {
        _checkingCachedSession = false;
        _cachedUser = cachedUser;
      });

      // Si hay usuario cacheado, verificar token
      if (cachedUser != null) {
        final isTokenValid = authProvider.isTokenValidLocally(
          authProvider.token ?? '',
        );
        if (isTokenValid) {
          // Auto-redirigir después de un breve delay
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            // En lugar de llamar directamente, hacer login con usuario cacheado
            _loginWithCachedUser();
          }
        }
      }
    } catch (e) {
      setState(() {
        _checkingCachedSession = false;
      });
    }
  }

  String? _validateUsernameOrEmail(String? value) {
    return Validators.validateUsernameOrEmail(value);
  }

  String? _validatePassword(String? value) {
    return Validators.validatePassword(value);
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usernameOrEmail = _usernameOrEmailController.text.trim();
      final password = _passwordController.text;

      // Usar el método login con parámetro forceRefresh
      final success = await authProvider.login(
        usernameOrEmail,
        password,
        forceRefresh: false,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          DialogErrorHandler.showSuccessSnackbar(
            context: context,
            message: '✅ Sesión iniciada exitosamente',
          );
        }
      } else {
        final error = authProvider.error ?? 'Error desconocido';
        final isNetworkError =
            error.contains('conexión') ||
            error.contains('internet') ||
            error.contains('red') ||
            error.contains('Conexión');

        if (mounted) {
          DialogErrorHandler.showErrorDialog(
            context: context,
            title: 'Error de autenticación',
            technicalError: error,
            showRetryButton: isNetworkError,
            onRetry: isNetworkError ? _performLogin : null,
          );
        }
      }
    }
  }

  // Iniciar sesión con usuario cacheado (modo offline)
  // En _loginWithCachedUser:
  Future<void> _loginWithCachedUser() async {
    if (_cachedUser == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Restaurando sesión...'),
          ],
        ),
        content: Text('Usando sesión guardada de ${_cachedUser!.username}'),
      ),
    );

    final success = await authProvider.restoreCachedSession();
    if (mounted) {
      Navigator.of(context).pop(); // Cerrar loading
    }

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: '✅ Sesión restaurada (Modo lectura)',
        );
      }
    } else {
      // No se pudo restaurar
      setState(() {
        _cachedUser = null;
      });

      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title: 'Sesión expirada',
          technicalError:
              'La sesión guardada ha expirado. Se requiere conexión para iniciar sesión nuevamente.',
        );
      }
    }
  }

  // En el texto del modo offline, cambia a:

  // Mostrar opción de sesión cacheada
  Widget _buildCachedSessionOption() {
    if (_checkingCachedSession) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Buscando sesión guardada...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_cachedUser != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sesión guardada encontrada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cachedUser!.username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _cachedUser!.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Solo lectura disponible',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.login, size: 16),
                      label: Text('Continuar offline'),
                      onPressed: _loginWithCachedUser,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      icon: Icon(Icons.cancel, size: 16),
                      label: Text('Usar otra cuenta'),
                      onPressed: () => setState(() {
                        _cachedUser = null;
                      }),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveContainer(
        child: Column(
          children: [
            // Logo/Header responsive
            SizedBox(
              height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 40,
                tablet: 60,
                desktop: 80,
              ),
            ),

            Icon(
              Icons.contacts,
              size: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 80,
                tablet: 100,
                desktop: 120,
              ),
              color: Colors.blue[700],
            ),

            const SizedBox(height: 16),

            ResponsiveText(
              text: 'Directorio Telefónico',
              size: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
            ResponsiveText(
              text: 'Desoft',
              size: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),

            const SizedBox(height: 8),

            ResponsiveText(
              text: 'Ingrese sus Credenciales',
              size: 16,
              color: Colors.grey[600],
            ),

            SizedBox(
              height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 20,
                tablet: 30,
                desktop: 40,
              ),
            ),

            // Opción de sesión cacheada
            _buildCachedSessionOption(),

            SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameOrEmailController,
                    decoration: InputDecoration(
                      labelText: 'Usuario o Correo electrónico',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'admin o admin@empresa.com',
                    ),
                    validator: _validateUsernameOrEmail,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Ingresa tu contraseña',
                    ),
                    validator: _validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _performLogin(),
                  ),

                  const SizedBox(height: 40),

                  // Loading y botón
                  if (authProvider.loading || authProvider.isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Verificando credenciales...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                  else
                    ResponsiveButton(
                      text: 'Iniciar Sesión',
                      onPressed: _performLogin,
                      backgroundColor: Colors.blue[700]!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/screen/calendar/calendar_screen.dart\n```
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/efemeride.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/efemeride_provider.dart';
import '../../widgets/calendar/efemeride_dialog.dart';
import '../../widgets/calendar/event_details_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Event>> events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = 'todos';
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    events = {};

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // void _loadInitialData() {
  //   final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
  //   final efemerideProvider = Provider.of<EfemerideProvider>(
  //     context,
  //     listen: false,
  //   );

  //   // USAR loadInitialData en lugar de loadWorkers
  //   if (!workerProvider.hasLoaded) {
  //     workerProvider.loadInitialData().then((_) {
  //       if (mounted) {
  //         _loadBirthdays();
  //       }
  //     });
  //   } else {
  //     _loadBirthdays();
  //   }

  //   // USAR loadInitialData en lugar de loadEfemerides
  //   if (!efemerideProvider.hasLoaded) {
  //     efemerideProvider.loadInitialData().then((_) {
  //       _loadEfemerides();
  //     });
  //   } else {
  //     _loadEfemerides();
  //   }
  // }
  void _loadInitialData() {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final efemerideProvider = Provider.of<EfemerideProvider>(
      context,
      listen: false,
    );

    // Cargar trabajadores primero
    if (!workerProvider.hasLoaded) {
      workerProvider.loadWorkers().then((_) {
        if (mounted) {
          _loadBirthdays();
        }
      });
    } else {
      _loadBirthdays();
    }

    // Cargar efemérides
    if (!efemerideProvider.hasLoaded) {
      efemerideProvider.loadEfemerides().then((_) {
        if (mounted) {
          _loadEfemerides();
        }
      });
    } else {
      _loadEfemerides();
    }
  }

  void _loadBirthdays() {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    // Limpiar solo cumpleaños
    final keysToRemove = <DateTime>[];
    events.forEach((key, value) {
      final newValue = value
          .where((event) => event.type != EventType.birthday)
          .toList();
      if (newValue.isEmpty) {
        keysToRemove.add(key);
      } else {
        events[key] = newValue;
      }
    });

    for (var key in keysToRemove) {
      events.remove(key);
    }

    for (var worker in workerProvider.workers) {
      final birthdayDate = worker.birthdayDate;
      if (birthdayDate != null) {
        // Cumpleaños para el año actual del calendario
        final eventDate = DateTime(
          _focusedDay.year,
          birthdayDate.month,
          birthdayDate.day,
        );

        events[eventDate] = [
          ...(events[eventDate] ?? []),
          Event(
            title: 'Cumpleaños de ${worker.fullName}',
            type: EventType.birthday,
            date: eventDate,
            worker: worker,
          ),
        ];
      }
    }

    if (mounted) setState(() {});
  }

  void _loadEfemerides() {
    final efemerideProvider = Provider.of<EfemerideProvider>(
      context,
      listen: false,
    );

    // Limpiar solo efemérides
    final keysToRemove = <DateTime>[];
    events.forEach((key, value) {
      final newValue = value
          .where((event) => event.type != EventType.efemeride)
          .toList();
      if (newValue.isEmpty) {
        keysToRemove.add(key);
      } else {
        events[key] = newValue;
      }
    });

    for (var key in keysToRemove) {
      events.remove(key);
    }

    // Cargar efemérides para el año actual del calendario
    for (var efemeride in efemerideProvider.efemerides) {
      final eventDate = DateTime(
        _focusedDay.year,
        efemeride.fecha.month,
        efemeride.fecha.day,
      );

      events[eventDate] = [
        ...(events[eventDate] ?? []),
        Event(
          title: efemeride.dato,
          type: EventType.efemeride,
          date: eventDate,
          efemeride: efemeride,
        ),
      ];
    }

    if (mounted) setState(() {});
  }

  void _refreshEvents() {
    setState(() {
      events = {};
    });
    _loadBirthdays();
    _loadEfemerides();
  }

  void _refreshEventsForCurrentYear() {
    _loadBirthdays();
    _loadEfemerides();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final allEvents = events[DateTime(day.year, day.month, day.day)] ?? [];

    if (_selectedFilter == 'todos') {
      return allEvents;
    } else if (_selectedFilter == 'cumpleaños') {
      return allEvents
          .where((event) => event.type == EventType.birthday)
          .toList();
    } else if (_selectedFilter == 'efemerides') {
      return allEvents
          .where((event) => event.type == EventType.efemeride)
          .toList();
    }

    return allEvents;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final dayEvents = _getEventsForDay(selectedDay);
    if (dayEvents.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            EventDetailsDialog(date: selectedDay, events: dayEvents),
      );
    }
  }

  int _getEventCountByType(EventType type) {
    return events.entries
        .where(
          (entry) =>
              entry.key.month == _focusedDay.month &&
              entry.key.year == _focusedDay.year,
        )
        .fold(
          0,
          (count, entry) =>
              count + entry.value.where((event) => event.type == type).length,
        );
  }

  int _getTotalEventCountForMonth() {
    return _getEventCountByType(EventType.birthday) +
        _getEventCountByType(EventType.efemeride);
  }

  // NUEVO: Función para sincronizar efemérides
  Future<void> _syncEfemerides(EfemerideProvider provider) async {
    final success = await provider.syncEfemerides();

    if (success) {
      _showSnackBar('✅ Efemérides sincronizadas');
      _refreshEvents();
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  void _showAddEfemerideDialog() {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar efemérides',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EfemerideDialog(
        onSave: (nuevaEfemeride) async {
          final success = await provider.createEfemeride(
            nuevaEfemeride.fecha,
            nuevaEfemeride.dato,
            nuevaEfemeride.detalle,
          );
          if (success) {
            _showSnackBar('✅ Efeméride creada exitosamente');
            _refreshEvents();
          } else {
            _showSnackBar('❌ Error: ${provider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _editEfemeride(Efemeride efemeride) {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para editar efemérides', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EfemerideDialog(
        efemeride: efemeride,
        onSave: (updatedEfemeride) async {
          final efemerideToUpdate = updatedEfemeride.copyWith(id: efemeride.id);
          final success = await provider.updateEfemeride(efemerideToUpdate);
          if (success) {
            _showSnackBar('✅ Efeméride actualizada exitosamente');
            _refreshEvents();
          } else {
            _showSnackBar('❌ Error: ${provider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _deleteEfemeride(Efemeride efemeride) {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar efemérides',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text('Eliminar Efeméride', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 40, color: Colors.purple[700]),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              efemeride.dato,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '📅 ${efemeride.displayDate}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await provider.deleteEfemeride(efemeride.id);

              if (success) {
                _showSnackBar('🗑️ Efeméride eliminada exitosamente');
                _refreshEvents();
              } else {
                _showSnackBar('❌ Error: ${provider.error}', isError: true);
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEfemeridesList() {
    // final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.list, color: Colors.purple[700], size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lista de Efemérides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),

                  // NUEVO: Indicador de estado offline
                  Consumer<EfemerideProvider>(
                    builder: (context, efProvider, child) {
                      if (efProvider.isOffline) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Offline',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Estadísticas
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Consumer<EfemerideProvider>(
                          builder: (context, efProvider, child) {
                            return Column(
                              children: [
                                Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${efProvider.efemerides.length}${efProvider.isOffline ? ' (offline)' : ''}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: efProvider.isOffline
                                        ? Colors.orange[700]
                                        : Colors.purple[700],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    if (isAdmin)
                      Row(
                        children: [
                          // NUEVO: Botón de sincronización si está offline
                          Consumer<EfemerideProvider>(
                            builder: (context, efProvider, child) {
                              if (efProvider.isOffline) {
                                return IconButton(
                                  icon: Icon(
                                    Icons.cloud_upload,
                                    size: 20,
                                    color: Colors.purple[700],
                                  ),
                                  onPressed: efProvider.syncing
                                      ? null
                                      : () => _syncEfemerides(efProvider),
                                  tooltip: 'Sincronizar efemérides',
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),

                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Agregar',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddEfemerideDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Lista
              Expanded(
                child: Consumer<EfemerideProvider>(
                  builder: (context, efProvider, child) {
                    if (efProvider.loading && !efProvider.hasLoaded) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple[700],
                        ),
                      );
                    }

                    if (efProvider.hasError && !efProvider.hasLoaded) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              efProvider.isOffline
                                  ? Icons.cloud_off
                                  : Icons.error_outline,
                              size: 60,
                              color: efProvider.isOffline
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              efProvider.isOffline
                                  ? 'Modo offline'
                                  : 'Error al cargar efemérides',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                efProvider.isOffline && efProvider.hasLocalData
                                    ? 'Mostrando ${efProvider.localDataCount} efemérides almacenadas localmente.'
                                    : efProvider.error,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return efProvider.efemerides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  efProvider.isOffline
                                      ? Icons.cloud_off
                                      : Icons.event_note,
                                  size: 60,
                                  color: efProvider.isOffline
                                      ? Colors.orange[300]
                                      : Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  efProvider.isOffline &&
                                          efProvider.hasLocalData
                                      ? 'No hay efemérides locales'
                                      : 'No hay efemérides registradas',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  efProvider.isOffline
                                      ? 'Conéctate a internet para cargar las efemérides.'
                                      : 'Agrega la primera efeméride',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: efProvider.efemerides.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
                            itemBuilder: (context, index) {
                              final efemeride = efProvider.efemerides[index];
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${efemeride.fecha.day}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  efemeride.dato,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${efemeride.fecha.day}/${efemeride.fecha.month}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: isAdmin
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _editEfemeride(efemeride);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _deleteEfemeride(efemeride),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(efemeride.dato),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '📅 Fecha: ${efemeride.displayDate}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            if (efemeride.detalle.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  efemeride.detalle,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        if (isAdmin)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _editEfemeride(efemeride);
                                            },
                                            child: Text('Editar'),
                                          ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cerrar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue[700]),
            SizedBox(width: 8),
            Flexible(
              child: Text('Estadísticas del Mes', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estadísticas por tipo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatItem(
                    'Total de Eventos',
                    Icons.event,
                    Colors.blue[700]!,
                    _getTotalEventCountForMonth().toString(),
                  ),
                  SizedBox(height: 12),
                  _buildStatItem(
                    'Cumpleaños',
                    Icons.cake,
                    Colors.pink[700]!,
                    _getEventCountByType(EventType.birthday).toString(),
                  ),
                  SizedBox(height: 12),
                  _buildStatItem(
                    'Efemérides',
                    Icons.history,
                    Colors.purple[700]!,
                    _getEventCountByType(EventType.efemeride).toString(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Información del mes
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Mes: ${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  Widget _buildStatItem(
    String label,
    IconData icon,
    Color color,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;
    final workerProvider = Provider.of<WorkerProvider>(context);
    final efemerideProvider = Provider.of<EfemerideProvider>(context);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Calendario',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.blue[700],
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // NUEVO: Botón de sincronización offline para efemérides
            Consumer<EfemerideProvider>(
              builder: (context, efProvider, child) {
                if (efProvider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                if (efProvider.isOffline) {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_off,
                      color: Colors.orange[100],
                      size: 24,
                    ),
                    onPressed: () => _syncEfemerides(efProvider),
                    tooltip: 'Efemérides offline - Toque para sincronizar',
                  );
                }

                return SizedBox.shrink();
              },
            ),

            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _showStatistics,
              tooltip: 'Estadísticas',
            ),
            IconButton(
              icon: Icon(Icons.list, color: Colors.white, size: 24),
              onPressed: _showEfemeridesList,
              tooltip: 'Lista de efemérides',
            ),
            if (isAdmin)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _showAddEfemerideDialog,
                tooltip: 'Agregar efeméride',
              ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                _refreshEvents();
                _showSnackBar('🔄 Calendario actualizado');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: workerProvider.loading || efemerideProvider.loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue[700]),
                    SizedBox(height: 16),
                    Text(
                      'Cargando calendario...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final isVerySmallScreen = screenHeight < 500;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                      child: Column(
                        children: [
                          // Filtros
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              padding: EdgeInsets.all(
                                isVerySmallScreen ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildFilterButton(
                                    'todos',
                                    'Todos',
                                    Icons.event,
                                  ),
                                  _buildFilterButton(
                                    'cumpleaños',
                                    'Cumpleaños',
                                    Icons.cake,
                                  ),
                                  _buildFilterButton(
                                    'efemerides',
                                    'Efemérides',
                                    Icons.history,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Header informativo
                          Container(
                            padding: EdgeInsets.all(
                              isVerySmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: isVerySmallScreen ? 8 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Calendario Corporativo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                          fontSize: isVerySmallScreen ? 14 : 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Cumpleaños del personal y efemérides importantes',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isVerySmallScreen ? 12 : 14,
                                        ),
                                      ),

                                      // NUEVO: Indicador de estado offline
                                      Consumer<EfemerideProvider>(
                                        builder: (context, efProvider, child) {
                                          if (efProvider.isOffline) {
                                            return Column(
                                              children: [
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.orange[200]!,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_off,
                                                        size: 12,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Modo offline - Efemérides cargadas localmente',
                                                        style: TextStyle(
                                                          fontSize:
                                                              isVerySmallScreen
                                                              ? 9
                                                              : 11,
                                                          color: Colors
                                                              .orange[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return SizedBox.shrink();
                                        },
                                      ),

                                      if (isAdmin) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Modo Administrador - Puedes gestionar efemérides',
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontSize: isVerySmallScreen
                                                ? 10
                                                : 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Leyenda de eventos
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLegendItem(
                                  Icons.cake,
                                  'Cumpleaños',
                                  Colors.pink[700]!,
                                  isVerySmallScreen,
                                ),
                                _buildLegendItem(
                                  Icons.history,
                                  'Efemérides',
                                  Colors.purple[700]!,
                                  isVerySmallScreen,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Calendario
                          Container(
                            height: _getCalendarHeight(screenHeight),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isVerySmallScreen ? 8 : 12,
                              ),
                              child: TableCalendar(
                                locale: 'es_ES',
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: isVerySmallScreen ? 14 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: Colors.blue[700],
                                    size: isVerySmallScreen ? 20 : 28,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.blue[700],
                                    size: isVerySmallScreen ? 20 : 28,
                                  ),
                                  headerPadding: EdgeInsets.symmetric(
                                    vertical: isVerySmallScreen ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  weekendStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                  ),
                                  selectedTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  todayTextStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  defaultTextStyle: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  outsideTextStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isVerySmallScreen ? 10 : 12,
                                  ),
                                  markerMargin: EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                ),
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                eventLoader: _getEventsForDay,
                                onDaySelected: _onDaySelected,
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                  _refreshEventsForCurrentYear();
                                },
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, date, events) {
                                    if (events.isEmpty) return null;

                                    final eventList = events
                                        .cast<Event>()
                                        .toList();
                                    final hasBirthday = eventList.any(
                                      (e) => e.type == EventType.birthday,
                                    );
                                    final hasEfemeride = eventList.any(
                                      (e) => e.type == EventType.efemeride,
                                    );

                                    Color markerColor;
                                    IconData markerIcon;

                                    if (hasBirthday && hasEfemeride) {
                                      markerColor = Colors.blue[700]!;
                                      markerIcon = Icons.event;
                                    } else if (hasBirthday) {
                                      markerColor = Colors.pink[700]!;
                                      markerIcon = Icons.cake;
                                    } else {
                                      markerColor = Colors.purple[700]!;
                                      markerIcon = Icons.history;
                                    }

                                    return Positioned(
                                      bottom: 1,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: markerColor.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: markerColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          markerIcon,
                                          size: isVerySmallScreen ? 10 : 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Resumen del mes
                          Container(
                            padding: EdgeInsets.all(
                              isVerySmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Resumen del Mes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: isVerySmallScreen ? 14 : 16,
                                  ),
                                ),
                                SizedBox(height: isVerySmallScreen ? 8 : 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMonthSummary(
                                      'Cumpleaños',
                                      Icons.cake,
                                      Colors.pink[700]!,
                                      _getEventCountByType(EventType.birthday),
                                      isVerySmallScreen,
                                    ),
                                    _buildMonthSummary(
                                      'Efemérides',
                                      Icons.history,
                                      Colors.purple[700]!,
                                      _getEventCountByType(EventType.efemeride),
                                      isVerySmallScreen,
                                    ),
                                    _buildMonthSummary(
                                      'Total',
                                      Icons.event,
                                      Colors.blue[700]!,
                                      _getTotalEventCountForMonth(),
                                      isVerySmallScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 8 : 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getCalendarHeight(double screenHeight) {
    if (screenHeight < 500) {
      return 370;
    } else if (screenHeight < 600) {
      return 410;
    } else if (screenHeight < 700) {
      return 450;
    } else if (screenHeight < 800) {
      return 490;
    } else {
      return 530;
    }
  }

  Widget _buildLegendItem(
    IconData icon,
    String text,
    Color color,
    bool isSmall,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSummary(
    String title,
    IconData icon,
    Color color,
    int count,
    bool isSmall,
  ) {
    return Column(
      children: [
        Container(
          width: isSmall ? 36 : 48,
          height: isSmall ? 36 : 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: isSmall ? 18 : 24, color: color),
        ),
        SizedBox(height: isSmall ? 4 : 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: isSmall ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
\n```\n
\n## Archivo: lib/screen/directory/create_user_screen.dart\n```
import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../utils/validators.dart';
import '../../models/rol.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  CreateUserScreenState createState() => CreateUserScreenState();
}

class CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late UserProvider _userProvider;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userProvider = UserProvider();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final success = await _userProvider.createUser(
        nombreUsuario: _usernameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        rol: _userProvider.selectedRol,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(_userProvider.error);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Éxito'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Usuario creado exitosamente:'),
            const SizedBox(height: 12),
            Text('👤 ${_usernameController.text}'),
            Text('📧 ${_emailController.text}'),
            Text('🎯 Rol: ${_userProvider.selectedRol.nombre.toUpperCase()}'),
            const SizedBox(height: 16),
            if (_userProvider.selectedRol.nombre == 'admin')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚠️ Este usuario tendrá acceso de administrador',
                  style: TextStyle(color: Colors.amber[800], fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver a la lista'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // En la clase _CreateUserScreenState

  String? _validateUsername(String? value) {
    return Validators.validateUsername(value);
  }

  String? _validateEmail(String? value) {
    return Validators.validateEmail(value);
  }

  String? _validatePassword(String? value) {
    return Validators.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar Rol *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar los roles disponibles
        Row(
          children: [
            // Botón para CONSULT
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _userProvider.setSelectedRol(Rol.consult);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _userProvider.selectedRol.nombre == 'consult'
                        ? Colors.green[50]
                        : Colors.white,
                    border: Border.all(
                      color: _userProvider.selectedRol.nombre == 'consult'
                          ? Colors.green
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search, // Icono para consultor
                        color: _userProvider.selectedRol.nombre == 'consult'
                            ? Colors.green
                            : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CONSULTOR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _userProvider.selectedRol.nombre == 'consult'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Solo consultas',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Botón para ADMIN
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _userProvider.setSelectedRol(Rol.admin);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _userProvider.selectedRol.nombre == 'admin'
                        ? Colors.red[50]
                        : Colors.white,
                    border: Border.all(
                      color: _userProvider.selectedRol.nombre == 'admin'
                          ? Colors.red
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: _userProvider.selectedRol.nombre == 'admin'
                            ? Colors.red
                            : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ADMINISTRADOR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _userProvider.selectedRol.nombre == 'admin'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Acceso completo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Información según el rol seleccionado
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _userProvider.selectedRol.nombre == 'admin'
              ? Container(
                  key: const ValueKey('admin-info'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Acceso completo: Puede gestionar usuarios, trabajadores y toda la información del sistema',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('consult-info'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo consultas: Puede ver información pero no modificarla',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Usuario',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_outlined, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Información'),
                  content: const Text(
                    'Complete todos los campos para crear un nuevo usuario.\n\n'
                    '• El nombre de usuario debe ser único\n'
                    '• El email debe ser único\n'
                    '• Seleccione el rol según los permisos necesarios',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Título
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue[700], size: 32),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Usuario',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Registre un nuevo usuario en el sistema',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Usuario
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateUsername,
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _validatePassword,
              ),

              const SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña *',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateConfirmPassword,
              ),

              const SizedBox(height: 24),

              // Selector de Rol
              _buildRoleSelector(),

              const SizedBox(height: 32),

              // Botones
              if (_isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blue[700]),
                    const SizedBox(height: 16),
                    const Text('Creando usuario...'),
                  ],
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _createUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'CREAR USUARIO',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/screen/directory/departments_screen.dart\n```
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/department_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/local_provider.dart';
import '../../services/call_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/department_dialog.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  DepartmentsScreenState createState() => DepartmentsScreenState();
}

class DepartmentsScreenState extends State<DepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Variables para importación Excel
  String? _selectedExcelFilePath;
  List<Map<String, dynamic>> _previewData = [];
  bool _isProcessingExcel = false;

  // bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

      departmentProvider.clearSearch();
      departmentProvider.loadInitialData();

      if (!localProvider.hasLoaded) {
        localProvider.loadLocals();
      }
    });
  }

  void _onSearchChanged() {
    _searchDebouncer.run(() {
      if (mounted) {
        final query = _searchController.text;
        final departmentProvider = Provider.of<DepartmentProvider>(
          context,
          listen: false,
        );

        setState(() {});

        if (query.isEmpty) {
          departmentProvider.clearSearch();
        } else {
          departmentProvider.searchDepartments(query);
        }
      }
    });
  }

  // ============ MÉTODOS DE AGREGAR DEPARTAMENTOS ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddDepartmentOptions,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.orange[700],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  // Mostrar opciones de agregar
  void _showAddDepartmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Agregar Departamentos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Selecciona cómo deseas agregar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Opción: Agregar manual
              _buildOptionCard(
                icon: Icons.business_center,
                title: 'Agregar Manual',
                subtitle: 'Ingresar datos uno por uno',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showAddDepartmentDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples departamentos desde archivo .xlsx',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Widget para cada opción
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ============ DIÁLOGO DE IMPORTACIÓN EXCEL ============

  void _showExcelImportDialog() {
    _selectedExcelFilePath = null;
    _previewData = [];
    _isProcessingExcel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Importar Excel'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un archivo Excel (.xlsx) con la estructura requerida',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // Área de selección de archivo
                    GestureDetector(
                      onTap: _isProcessingExcel
                          ? null
                          : () => _pickExcelFile(setState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedExcelFilePath != null
                                ? Colors.green
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedExcelFilePath != null
                              ? Colors.green[50]
                              : Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedExcelFilePath != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: _selectedExcelFilePath != null
                                  ? Colors.green
                                  : Colors.green[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedExcelFilePath != null
                                  ? _selectedExcelFilePath!.split('/').last
                                  : 'Toca para seleccionar archivo',
                              style: TextStyle(
                                color: _selectedExcelFilePath != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontWeight: _selectedExcelFilePath != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedExcelFilePath == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Formatos soportados: .xlsx, .xls',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descargar plantilla
                    InkWell(
                      onTap: _downloadExcelTemplate,
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_download,
                            size: 18,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessingExcel) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Procesando archivo...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Previsualización de datos
                    if (_previewData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                itemCount: _previewData.length > 5
                                    ? 5
                                    : _previewData.length,
                                itemBuilder: (context, index) {
                                  final item = _previewData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${index + 1}. ${item['nombre'] ?? 'Sin nombre'} - ${item['telefono'] ?? 'Sin teléfono'}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessingExcel
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isProcessingExcel || _selectedExcelFilePath == null
                      ? null
                      : () => _processExcelFile(context, setState),
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Seleccionar archivo Excel
  Future<void> _pickExcelFile(StateSetter setState) async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para importar archivos.',
            isError: true,
          );
          return;
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedExcelFilePath = result.files.single.path;
          _previewData = [];
        });

        // Leer y previsualizar el archivo
        await _previewExcelFile(result.files.single.path!, setState);
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar archivo: $e', isError: true);
    }
  }

  // Previsualizar archivo Excel
  Future<void> _previewExcelFile(String filePath, StateSetter setState) async {
    try {
      final rows = await ExcelImportService.readRowsFromFile(filePath);
      final parsedRows = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'telefono'],
      );

      if (parsedRows.isEmpty) {
        throw Exception('No se encontraron registros válidos en el archivo.');
      }

      if (mounted) {
        setState(() {
          _previewData = parsedRows;
        });
      }
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      if (mounted) {
        setState(() {
          _selectedExcelFilePath = null;
          _previewData = [];
        });
      }
    }
  }

  // Procesar archivo Excel
  Future<void> _processExcelFile(
    BuildContext context,
    StateSetter setState,
  ) async {
    if (_selectedExcelFilePath == null || _previewData.isEmpty) {
      _showSnackBar('No hay datos para importar', isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingExcel = true;
      });
    }

    try {
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );

      int successCount = 0;
      int skippedCount = 0;

      for (var data in _previewData) {
        try {
          final name = data['nombre']?.toString().trim() ?? '';
          final phone = data['telefono']?.toString().trim() ?? '';

          if (name.isEmpty) {
            skippedCount++;
            continue;
          }

          final success = await departmentProvider.createDepartment(
            name,
            phone,
          );
          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (successCount > 0) {
        _showSnackBar(
          '✅ $successCount departamentos importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await departmentProvider.loadDepartments(forceRefresh: true);
      } else {
        _showSnackBar(
          '❌ No se pudo importar ningún departamento',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('❌ Error al importar: ${e.toString()}', isError: true);
    }
  }

  // Descargar plantilla de ejemplo
  Future<void> _downloadExcelTemplate() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para descargar archivos.',
            isError: true,
          );
          return;
        }
      }

      _showSnackBar('📥 Generando plantilla...');
      final filePath = await ExcelTemplateService.generateDepartmentsTemplate();
      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        _showSnackBar('✅ Plantilla lista en: $filePath');
      } else {
        _showSnackBar('❌ No se pudo generar la plantilla', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '❌ Error al generar plantilla: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ============ MÉTODOS DE MANEJO DE DEPARTAMENTOS ============

  void _showAddDepartmentDialog() {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DepartmentDialog(
        onSave: (department) async {
          debugPrint(
            '[DepartmentsScreen][CREATE] Starting create: ${department.toJson()}',
          );
          final success = await departmentProvider.createDepartment(
            department.name,
            department.phone,
          );
          if (success) {
            _showSnackBar('✅ Departamento creado exitosamente');
          } else {
            _showSnackBar(
              '❌ Error: ${departmentProvider.error}',
              isError: true,
            );
          }
          return success;
        },
        departmentProvider: departmentProvider,
      ),
    );
  }

  void _showEditDepartmentDialog(Department department) {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para editar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DepartmentDialog(
        department: department,
        onSave: (updatedDepartment) async {
          final success = await departmentProvider.updateDepartment(
            updatedDepartment.copyWith(id: department.id),
          );
          if (success) {
            _showSnackBar('✅ Departamento actualizado exitosamente');
          } else {
            _showSnackBar(
              '❌ Error: ${departmentProvider.error}',
              isError: true,
            );
          }
          return success;
        },
        departmentProvider: departmentProvider,
      ),
    );
  }

  void _showDeleteConfirmation(Department department) {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Eliminar Departamento', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.work, size: 40, color: Colors.orange[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              department.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            if (department.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${department.phone}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.of(context).pop();

              // setState(() {
              //   departmentProvider.loading = true;
              // });

              final success = await departmentProvider.deleteDepartment(
                department.id,
              );

              if (!mounted) return;

              // setState(() {
              //   _isDeleting = false;
              // });

              if (success) {
                _showSnackBar('🗑️ Departamento eliminado exitosamente');
              } else {
                _showSnackBar(
                  '❌ Error: ${departmentProvider.error}',
                  isError: true,
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============ MÉTODOS DE SINCRONIZACIÓN ============

  Future<void> _syncDepartments(DepartmentProvider provider) async {
    final success = await provider.syncDepartments();

    if (success) {
      _showSnackBar('✅ Departamentos sincronizados');
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final localProvider = Provider.of<LocalProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Departamentos',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.orange[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Botón de sincronización offline
            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                if (provider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: provider.isOffline
                        ? Colors.orange[100]
                        : Colors.white,
                    size: 24,
                  ),
                  onPressed: provider.isOffline
                      ? () => _syncDepartments(departmentProvider)
                      : null,
                  tooltip: provider.isOffline
                      ? 'Modo offline - Toque para sincronizar'
                      : 'En línea',
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                departmentProvider.loadDepartments(forceRefresh: true);
                _showSnackBar('🔄 Actualizando lista...');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        // body: _buildBody(departmentProvider, localProvider, isAdmin),
        body: Stack(
          children: [
            _buildBody(departmentProvider, localProvider, isAdmin),
            if (departmentProvider.loading && departmentProvider.hasLoaded) ...[
              const ModalBarrier(dismissible: false, color: Colors.black54),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      "🔄 Actualizando lista...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBody(
    DepartmentProvider departmentProvider,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    if (departmentProvider.loading && !departmentProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              'Cargando departamentos...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (departmentProvider.hasError && !departmentProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              departmentProvider.isOffline
                  ? Icons.cloud_off
                  : Icons.error_outline,
              size: 64,
              color: departmentProvider.isOffline ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              departmentProvider.isOffline
                  ? 'Modo offline'
                  : 'Error al cargar departamentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                departmentProvider.isOffline && departmentProvider.hasLocalData
                    ? 'Mostrando ${departmentProvider.localDataCount} departamentos almacenados localmente.'
                    : departmentProvider.error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            if (departmentProvider.isOffline && departmentProvider.hasLocalData)
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    label: const Text(
                      'Sincronizar ahora',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _syncDepartments(departmentProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => departmentProvider.loadDepartments(),
                    child: const Text('Continuar en modo offline'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => departmentProvider.loadDepartments(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final lites = departmentProvider.departmentLites;

    return Column(
      children: [
        // Barra de búsqueda optimizada
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          departmentProvider.clearSearch();
                        },
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Contador y estadísticas optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Consumer<DepartmentProvider>(
                    builder: (context, provider, child) {
                      final totalCount = provider.isSearching
                          ? lites.length
                          : (provider.isOffline
                                ? provider.localDataCount
                                : provider.totalDepartments);

                      return Text(
                        '$totalCount departamentos${provider.isOffline ? ' (offline)' : ''}',
                        style: TextStyle(
                          color: provider.isOffline
                              ? Colors.orange[700]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Consumer<DepartmentProvider>(
                builder: (context, provider, child) {
                  if (provider.isOffline) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lista de departamentos
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await departmentProvider.loadDepartments(forceRefresh: true);
              _showSnackBar('✅ Lista actualizada');
            },
            color: Colors.orange[700],
            child: lites.isEmpty && !departmentProvider.isLoadingMore
                ? _buildEmptyState(isAdmin, departmentProvider)
                : ListView.builder(
                    controller: departmentProvider.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        lites.length + (departmentProvider.hasMore ? 1 : 0),
                    itemExtent: 96,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index >= lites.length) {
                        return _buildLoadingIndicator(departmentProvider);
                      }

                      final departmentLite = lites[index];
                      return _buildDepartmentCard(
                        departmentLite,
                        localProvider,
                        isAdmin,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(DepartmentProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoadingMore
            ? CircularProgressIndicator(color: Colors.orange[700])
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDepartmentCard(
    DepartmentLite departmentLite,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _loadAndShowDepartmentDetails(
          departmentLite.id,
          localProvider,
          isAdmin,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        departmentLite.initials,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      departmentLite.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (departmentLite.hasPhone)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            departmentLite.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    final department = await _loadDepartmentById(
                      departmentLite.id,
                    );
                    if (department != null) {
                      if (value == 'edit') {
                        _showEditDepartmentDialog(department);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(department);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Department?> _loadDepartmentById(int id) async {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    return await departmentProvider.getDepartmentById(id);
  }

  Future<void> _loadAndShowDepartmentDetails(
    int departmentId,
    LocalProvider localProvider,
    bool isAdmin,
  ) async {
    final department = await _loadDepartmentById(departmentId);
    if (department != null && mounted) {
      _showDepartmentDetails(department, localProvider, isAdmin);
    }
  }

  Widget _buildEmptyState(bool isAdmin, DepartmentProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: provider.isOffline
                            ? Colors.orange[50]
                            : Colors.orange[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        provider.isOffline
                            ? Icons.cloud_off
                            : _searchController.text.isEmpty
                            ? Icons.work_outline
                            : Icons.search_off,
                        size: 60,
                        color: provider.isOffline
                            ? Colors.orange[300]
                            : Colors.orange[300],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.isOffline)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Modo offline',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Text(
                      _searchController.text.isEmpty
                          ? provider.isOffline
                                ? 'No hay datos locales de departamentos'
                                : 'No hay departamentos registrados'
                          : 'No se encontraron resultados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _searchController.text.isEmpty
                            ? provider.isOffline
                                  ? 'Conéctate a internet para cargar los departamentos.'
                                  : ''
                            : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                if (provider.isOffline && _searchController.text.isEmpty) {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.cloud_download,
                          color: Colors.white,
                        ),
                        label: const Text('Sincronizar desde internet'),
                        onPressed: () => _syncDepartments(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'O verifica tu conexión a internet',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  );
                }

                if (isAdmin && _searchController.text.isEmpty) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Agregar Primer Departamento',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _showAddDepartmentOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  provider.clearSearch();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentDetails(
    Department department,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle para arrastrar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header con icono
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          department.name.length >= 2
                              ? department.name.substring(0, 2).toUpperCase()
                              : department.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      department.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey[200]),

              // Información detallada
              _buildDetailSection(
                icon: Icons.phone,
                label: 'Teléfono',
                value: department.phone.isNotEmpty
                    ? department.phone
                    : 'No disponible',
                color: Colors.orange[700]!,
              ),

              const SizedBox(height: 20),

              // Acciones de contacto
              if (department.phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactAction(
                        Icons.phone,
                        'Llamar',
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _makePhoneCall(department.phone);
                        },
                      ),
                      _buildContactAction(
                        Icons.copy,
                        'Copiar',
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _copyPhoneNumber(department.phone);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDepartmentDialog(department);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(department);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    var status = await Permission.phone.status;

    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      _showSnackBar('📞 Llamando a $phoneNumber...');
      CallService.directCall(phoneNumber);
    } else {
      _showSnackBar('❌ Permiso denegado para hacer llamadas');
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.of(context).pop();

    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (mounted) {
      Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
          .then((value) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Número copiado: $cleanPhoneNumber'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          })
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al copiar el número'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/screen/directory/home_screen.dart\n```
import 'package:flutter/material.dart';
import '../../screen/directory/create_user_screen.dart';
import '../../screen/directory/local_screen.dart';
import 'package:provider/provider.dart';

import '../../models/rol.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shared/responsive_card.dart';
import '../../widgets/shared/responsive_text.dart';
import '../auth/login_screen.dart';
import '../calendar/calendar_screen.dart';
import '../setting/config_screen.dart';
import 'departments_screen.dart';
import 'workers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialAuthCheckDone = false;

  @override
  void initState() {
    super.initState();
    // Verificar auth solo UNA VEZ al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthOnce();
    });
  }

  void _checkAuthOnce() async {
    if (_initialAuthCheckDone) return;

    final authProvider = context.read<AuthProvider>();

    // Solo verificar si nunca se ha hecho
    if (!authProvider.hasCheckedAuth) {
      await authProvider.checkAuthStatus();
    }

    _initialAuthCheckDone = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: 'Directorio Telefónico',
          size: 20,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          // Botón de sincronización - CON SELECTOR para evitar rebuilds innecesarios
          Selector<AuthProvider, bool>(
            selector: (_, authProvider) => authProvider.isAuthenticated,
            builder: (context, isAuthenticated, child) {
              if (isAuthenticated) {
                return IconButton(
                  icon: Icon(Icons.sync, color: Colors.white),
                  onPressed: () => _syncData(context),
                  tooltip: 'Sincronizar datos',
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Botón de configuración - SIN Consumer
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigScreen()),
              );
            },
            tooltip: 'Configuración',
          ),

          // Botón de login/logout - CON SELECTOR
          Selector<AuthProvider, bool>(
            selector: (_, authProvider) => authProvider.isAuthenticated,
            builder: (context, isAuthenticated, child) {
              return IconButton(
                icon: Icon(
                  isAuthenticated ? Icons.logout : Icons.login,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isAuthenticated) {
                    _showLogoutConfirmation(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
                tooltip: isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
              );
            },
          ),
        ],
      ),
      body: Selector<AuthProvider, User?>(
        selector: (_, authProvider) => authProvider.user,
        builder: (context, currentUser, child) {
          return _buildBody(context, currentUser);
        },
      ),
      floatingActionButton: Selector<AuthProvider, bool>(
        selector: (_, authProvider) => authProvider.isAuthenticated,
        builder: (context, isAuthenticated, child) {
          if (isAuthenticated) {
            return FloatingActionButton(
              onPressed: () => _syncData(context),
              backgroundColor: Colors.blue[700],
              tooltip: 'Sincronizar datos',
              child: Icon(Icons.sync, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, User? currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con información del usuario
          _buildUserHeader(context, currentUser),

          const SizedBox(height: 16),

          // Grid de opciones
          Expanded(
            child: GridView.count(
              crossAxisCount: ResponsiveUtils.getResponsiveGridCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: _buildMenuItems(context, currentUser),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          text: currentUser != null
              ? 'Bienvenido, ${currentUser.username}'
              : 'Bienvenido',
          size: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),

        SizedBox(height: 4),

        if (currentUser != null)
          ResponsiveText(
            text: _getRoleDisplayName(currentUser.roles),
            size: 16,
            color: Colors.grey[600],
          ),

        SizedBox(height: 8),

        if (currentUser != null)
          ResponsiveText(
            text: currentUser.email,
            size: 14,
            color: Colors.grey[500],
          ),
      ],
    );
  }

  // Widget _buildConnectionStatus(BuildContext context) {
  //   return Consumer<AuthProvider>(
  //     builder: (context, authProvider, child) {
  //       final isOnline = authProvider
  //           .isAuthenticated; // Esto deberías cambiar por un connectivity check real

  //       return Container(
  //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: isOnline ? Colors.green[50] : Colors.grey[100],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(
  //             color: isOnline ? Colors.green : Colors.grey,
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               isOnline ? Icons.wifi : Icons.wifi_off,
  //               size: 16,
  //               color: isOnline ? Colors.green : Colors.grey,
  //             ),
  //             SizedBox(width: 8),
  //             ResponsiveText(
  //               text: isOnline ? 'Conectado' : 'Modo offline',
  //               size: 14,
  //               color: isOnline ? Colors.green[700] : Colors.grey[700],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Mostrar diálogo de confirmación para logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              await _performLogout(context);
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Realizar logout
  Future<void> _performLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await authProvider.logout();
    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sesión cerrada exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Sincronizar datos
  Future<void> _syncData(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para sincronizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sincronizando...'),
          ],
        ),
        content: const Text('Actualizando datos locales con el servidor'),
      ),
    );

    // Aquí deberías llamar a tu SyncService
    await Future.delayed(const Duration(seconds: 2)); // Simulación
    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Obtener nombre display del rol
  String _getRoleDisplayName(List<Rol> roles) {
    if (roles.isEmpty) return 'Usuario';

    final roleNames = roles.map((rol) {
      switch (rol.nombre.toLowerCase()) {
        case 'admin':
          return 'Administrador';
        case 'user':
        case 'consult':
          return 'Usuario';
        default:
          return rol.nombre;
      }
    }).toList();

    return roleNames.join(', ');
  }

  List<Widget> _buildMenuItems(BuildContext context, User? currentUser) {
    final isAdmin = currentUser?.isAdmin ?? false;
    final isAuthenticated = currentUser != null;

    final menuItems = <Widget>[
      // Opciones disponibles para todos
      _buildCategoryCard(
        context,
        'Trabajadores',
        Icons.people,
        Colors.blue,
        WorkersScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Locales',
        Icons.business,
        Colors.green,
        LocalScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Departamentos',
        Icons.work,
        Colors.orange,
        DepartmentsScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Calendario',
        Icons.calendar_month_outlined,
        Colors.purple,
        CalendarScreen(),
        available: true,
      ),
    ];

    // Opciones solo para administradores
    if (isAdmin && isAuthenticated) {
      menuItems.addAll([
        _buildCategoryCard(
          context,
          'Agregar Usuario',
          Icons.person_add_alt_1,
          Colors.red,
          CreateUserScreen(),
          available: true,
        ),
      ]);
    }

    return menuItems;
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen, {
    bool available = true,
  }) {
    return GestureDetector(
      onTap: available
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            }
          : null,
      child: Opacity(
        opacity: available ? 1.0 : 0.5,
        child: ResponsiveCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 32,
                    tablet: 36,
                    desktop: 40,
                  ),
                  color: available ? color : Colors.grey,
                ),
              ),

              SizedBox(height: 12),

              ResponsiveText(
                text: title,
                size: 16,
                fontWeight: FontWeight.bold,
                color: available ? Colors.blue[700] : Colors.grey[600],
                textAlign: TextAlign.center,
              ),

              if (!available)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: ResponsiveText(
                    text: '(Requiere login)',
                    size: 12,
                    color: Colors.grey[500],
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/screen/directory/local_screen.dart\n```
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/local.dart';
import '../../models/local_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/local_provider.dart';
import '../../services/call_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/local_dialog.dart';

class LocalScreen extends StatefulWidget {
  const LocalScreen({super.key});

  @override
  LocalScreenState createState() => LocalScreenState();
}

class LocalScreenState extends State<LocalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Variables para importación Excel
  String? _selectedExcelFilePath;
  List<Map<String, dynamic>> _previewData = [];
  bool _isProcessingExcel = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localProvider = Provider.of<LocalProvider>(context, listen: false);
      localProvider.clearSearch();
      localProvider.loadInitialData();
    });
  }

  void _onSearchChanged() {
    _searchDebouncer.run(() {
      if (mounted) {
        final query = _searchController.text;
        final localProvider = Provider.of<LocalProvider>(
          context,
          listen: false,
        );

        setState(() {});

        if (query.isEmpty) {
          localProvider.clearSearch();
        } else {
          localProvider.searchLocals(query);
        }
      }
    });
  }

  // ============ MÉTODOS DE AGREGAR LOCALES ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddLocalOptions,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.green[700],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  // Mostrar opciones de agregar
  void _showAddLocalOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Agregar Locales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Selecciona cómo deseas agregar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Opción: Agregar manual
              _buildOptionCard(
                icon: Icons.business_center,
                title: 'Agregar Manual',
                subtitle: 'Ingresar datos uno por uno',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showAddLocalDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples locales desde archivo .xlsx',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Widget para cada opción
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ============ DIÁLOGO DE IMPORTACIÓN EXCEL ============

  void _showExcelImportDialog() {
    _selectedExcelFilePath = null;
    _previewData = [];
    _isProcessingExcel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Importar Excel'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un archivo Excel (.xlsx) con la estructura requerida',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // Área de selección de archivo
                    GestureDetector(
                      onTap: _isProcessingExcel
                          ? null
                          : () => _pickExcelFile(setState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedExcelFilePath != null
                                ? Colors.green
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedExcelFilePath != null
                              ? Colors.green[50]
                              : Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedExcelFilePath != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: _selectedExcelFilePath != null
                                  ? Colors.green
                                  : Colors.green[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedExcelFilePath != null
                                  ? _selectedExcelFilePath!.split('/').last
                                  : 'Toca para seleccionar archivo',
                              style: TextStyle(
                                color: _selectedExcelFilePath != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontWeight: _selectedExcelFilePath != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedExcelFilePath == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Formatos soportados: .xlsx, .xls',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descargar plantilla
                    InkWell(
                      onTap: _downloadExcelTemplate,
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_download,
                            size: 18,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessingExcel) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Procesando archivo...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Previsualización de datos
                    if (_previewData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              child: ListView.builder(
                                itemCount: _previewData.length > 5
                                    ? 5
                                    : _previewData.length,
                                itemBuilder: (context, index) {
                                  final item = _previewData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${index + 1}. ${item['nombre'] ?? 'Sin nombre'} - ${item['telefono'] ?? 'Sin teléfono'}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessingExcel
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isProcessingExcel || _selectedExcelFilePath == null
                      ? null
                      : () => _processExcelFile(context, setState),
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Seleccionar archivo Excel
  Future<void> _pickExcelFile(StateSetter setState) async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para importar archivos.',
            isError: true,
          );
          return;
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedExcelFilePath = result.files.single.path;
          _previewData = [];
        });

        // Leer y previsualizar el archivo
        await _previewExcelFile(result.files.single.path!, setState);
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar archivo: $e', isError: true);
    }
  }

  // Previsualizar archivo Excel
  Future<void> _previewExcelFile(String filePath, StateSetter setState) async {
    try {
      final rows = await ExcelImportService.readRowsFromFile(filePath);
      final parsedRows = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'telefono'],
      );

      if (parsedRows.isEmpty) {
        throw Exception('No se encontraron registros válidos en el archivo.');
      }

      if (mounted) {
        setState(() {
          _previewData = parsedRows;
        });
      }
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      if (mounted) {
        setState(() {
          _selectedExcelFilePath = null;
          _previewData = [];
        });
      }
    }
  }

  // Procesar archivo Excel
  Future<void> _processExcelFile(
    BuildContext context,
    StateSetter setState,
  ) async {
    if (_selectedExcelFilePath == null || _previewData.isEmpty) {
      _showSnackBar('No hay datos para importar', isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingExcel = true;
      });
    }

    try {
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

      int successCount = 0;
      int skippedCount = 0;

      for (var data in _previewData) {
        try {
          final name = data['nombre']?.toString().trim() ?? '';
          final phone = data['telefono']?.toString().trim() ?? '';

          if (name.isEmpty) {
            skippedCount++;
            continue;
          }

          final success = await localProvider.createLocal(name, phone);
          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (successCount > 0) {
        _showSnackBar(
          '✅ $successCount locales importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await localProvider.loadLocals(forceRefresh: true);
      } else {
        _showSnackBar('❌ No se pudo importar ningún local', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('❌ Error al importar: ${e.toString()}', isError: true);
    }
  }

  // Descargar plantilla de ejemplo
  Future<void> _downloadExcelTemplate() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para descargar archivos.',
            isError: true,
          );
          return;
        }
      }

      _showSnackBar('📥 Generando plantilla...');
      final filePath = await ExcelTemplateService.generateLocalsTemplate();
      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        _showSnackBar('✅ Plantilla lista en: $filePath');
      } else {
        _showSnackBar('❌ No se pudo generar la plantilla', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '❌ Error al generar plantilla: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ============ MÉTODOS DE MANEJO DE LOCALES ============

  void _showAddLocalDialog() {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para agregar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LocalDialog(
        onSave: (local) async {
          final success = await localProvider.createLocal(
            local.name,
            local.phone,
          );
          if (success) {
            _showSnackBar('✅ Local creado exitosamente');
          } else {
            _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _showEditLocalDialog(Local local) {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para editar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LocalDialog(
        local: local,
        onSave: (updatedLocal) async {
          final success = await localProvider.updateLocal(
            updatedLocal.copyWith(id: local.id),
          );
          if (success) {
            _showSnackBar('✅ Local actualizado exitosamente');
          } else {
            _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Local local) {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para eliminar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Eliminar Local', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business, size: 40, color: Colors.green[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              local.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            if (local.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${local.phone}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await localProvider.deleteLocal(local.id);
              if (success) {
                _showSnackBar('🗑️ Local eliminado exitosamente');
              } else {
                _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============ MÉTODOS DE SINCRONIZACIÓN ============

  Future<void> _syncLocals(LocalProvider provider) async {
    final success = await provider.syncLocals();

    if (success) {
      _showSnackBar('✅ Locales sincronizados');
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final localProvider = Provider.of<LocalProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Locales',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.green[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Botón de sincronización offline
            Consumer<LocalProvider>(
              builder: (context, provider, child) {
                if (provider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: provider.isOffline
                        ? Colors.green[100]
                        : Colors.white,
                    size: 24,
                  ),
                  onPressed: provider.isOffline
                      ? () => _syncLocals(localProvider)
                      : null,
                  tooltip: provider.isOffline
                      ? 'Modo offline - Toque para sincronizar'
                      : 'En línea',
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                localProvider.loadLocals(forceRefresh: true);
                _showSnackBar('🔄 Actualizando lista...');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        // body: _buildBody(localProvider, isAdmin),
        body: Stack(
          children: [
            _buildBody(localProvider, isAdmin),

            if (localProvider.loading && localProvider.hasLoaded) ...[
              const ModalBarrier(dismissible: false, color: Colors.black54),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      "🔄 Actualizando lista...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBody(LocalProvider localProvider, bool isAdmin) {
    if (localProvider.loading && !localProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green[700]),
            const SizedBox(height: 16),
            Text(
              'Cargando locales...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (localProvider.hasError && !localProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              localProvider.isOffline ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: localProvider.isOffline ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              localProvider.isOffline
                  ? 'Modo offline'
                  : 'Error al cargar locales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                localProvider.isOffline && localProvider.hasLocalData
                    ? 'Mostrando ${localProvider.localDataCount} locales almacenados localmente.'
                    : localProvider.error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            if (localProvider.isOffline && localProvider.hasLocalData)
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    label: const Text(
                      'Sincronizar ahora',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _syncLocals(localProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => localProvider.loadLocals(),
                    child: const Text('Continuar en modo offline'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => localProvider.loadLocals(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final lites = localProvider.localLites;

    return Column(
      children: [
        // Barra de búsqueda optimizada
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          localProvider.clearSearch();
                        },
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Contador y estadísticas optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 6),
                  Consumer<LocalProvider>(
                    builder: (context, provider, child) {
                      final totalCount = provider.isSearching
                          ? lites.length
                          : (provider.isOffline
                                ? provider.localDataCount
                                : provider.totalLocals);

                      return Text(
                        '$totalCount locales${provider.isOffline ? ' (offline)' : ''}',
                        style: TextStyle(
                          color: provider.isOffline
                              ? Colors.green[700]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Consumer<LocalProvider>(
                builder: (context, provider, child) {
                  if (provider.isOffline) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lista de locales
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await localProvider.loadLocals(forceRefresh: true);
              _showSnackBar('✅ Lista actualizada');
            },
            color: Colors.green[700],
            child: lites.isEmpty && !localProvider.isLoadingMore
                ? _buildEmptyState(isAdmin, localProvider)
                : ListView.builder(
                    controller: localProvider.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: lites.length + (localProvider.hasMore ? 1 : 0),
                    itemExtent: 96,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index >= lites.length) {
                        return _buildLoadingIndicator(localProvider);
                      }

                      final localLite = lites[index];
                      return _buildLocalCard(localLite, isAdmin);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(LocalProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoadingMore
            ? CircularProgressIndicator(color: Colors.green[700])
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLocalCard(LocalLite localLite, bool isAdmin) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _loadAndShowLocalDetails(localLite.id, isAdmin),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localLite.initials,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localLite.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (localLite.hasPhone)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            localLite.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    final local = await _loadLocalById(localLite.id);
                    if (local != null) {
                      if (value == 'edit') {
                        _showEditLocalDialog(local);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(local);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Local?> _loadLocalById(int id) async {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    return await localProvider.getLocalById(id);
  }

  Future<void> _loadAndShowLocalDetails(int localId, bool isAdmin) async {
    final local = await _loadLocalById(localId);
    if (local != null && mounted) {
      _showLocalDetails(local, isAdmin);
    }
  }

  Widget _buildEmptyState(bool isAdmin, LocalProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<LocalProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: provider.isOffline
                            ? Colors.green[50]
                            : Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        provider.isOffline
                            ? Icons.cloud_off
                            : _searchController.text.isEmpty
                            ? Icons.business_outlined
                            : Icons.search_off,
                        size: 60,
                        color: provider.isOffline
                            ? Colors.green[300]
                            : Colors.green[300],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.isOffline)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Modo offline',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<LocalProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Text(
                      _searchController.text.isEmpty
                          ? provider.isOffline
                                ? 'No hay datos locales de locales'
                                : 'No hay locales registrados'
                          : 'No se encontraron resultados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _searchController.text.isEmpty
                            ? provider.isOffline
                                  ? 'Conéctate a internet para cargar los locales.'
                                  : ''
                            : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<LocalProvider>(
              builder: (context, provider, child) {
                if (provider.isOffline && _searchController.text.isEmpty) {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.cloud_download,
                          color: Colors.white,
                        ),
                        label: const Text('Sincronizar desde internet'),
                        onPressed: () => _syncLocals(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'O verifica tu conexión a internet',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  );
                }

                if (isAdmin && _searchController.text.isEmpty) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Agregar Primer Local',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _showAddLocalOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  provider.clearSearch();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
              ),
          ],
        ),
      ),
    );
  }

  void _showLocalDetails(Local local, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle para arrastrar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header con icono
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          local.name.length >= 2
                              ? local.name.substring(0, 2).toUpperCase()
                              : local.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      local.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey[200]),

              // Información detallada
              _buildDetailSection(
                icon: Icons.phone,
                label: 'Teléfono',
                value: local.phone.isNotEmpty ? local.phone : 'No disponible',
                color: Colors.green[700]!,
              ),

              const SizedBox(height: 20),

              // Acciones de contacto
              if (local.phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactAction(
                        Icons.phone,
                        'Llamar',
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _makePhoneCall(local.phone);
                        },
                      ),
                      _buildContactAction(
                        Icons.copy,
                        'Copiar',
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _copyPhoneNumber(local.phone);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.green),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditLocalDialog(local);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(local);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    var status = await Permission.phone.status;

    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      _showSnackBar('📞 Llamando a $phoneNumber...');
      CallService.directCall(phoneNumber);
    } else {
      _showSnackBar('❌ Permiso denegado para hacer llamadas');
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.of(context).pop();

    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (mounted) {
      Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
          .then((value) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Número copiado: $cleanPhoneNumber'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          })
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al copiar el número'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/screen/directory/onboarding_screen.dart\n```
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Slider data
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '¡Bienvenido al Directorio Telefónico Desoft!',
      description:
          'Accede rápidamente a la información de contacto '
          'de todos los trabajadores de Desoft.',
      image: Icons.contacts,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Consulta sin límites',
      description:
          'Puedes buscar trabajadores, departamentos y locales '
          'sin necesidad de iniciar sesión.',
      image: Icons.search,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Modo Administrador',
      description:
          'Inicia sesión con credenciales de administrador '
          'para agregar, editar o eliminar información.',
      image: Icons.admin_panel_settings,
      color: Colors.red,
    ),
    OnboardingPage(
      title: 'Configuración de Red Corporativa',
      description:
          'Importante: Para el correcto funcionamiento, '
          'primero debe poseer una linea coorporativa '
          'y ademas configura el APN "desoft" en tu dispositivo.',
      image: Icons.settings_cell,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Funcionalidades Especiales',
      description:
          '• Calendario de cumpleaños y efemérides\n'
          '• Llamadas directas desde la app\n'
          '• Copiar números de contacto\n'
          '• Acceso rápido a información',
      image: Icons.star,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (solo mostrar si no es la última página)
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Saltar',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicator y botones
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Siguiente'
                            : '¡Comenzar!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Back button (solo mostrar si no es la primera página)
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Atrás',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono
                    Container(
                      width: constraints.maxWidth * 0.3,
                      height: constraints.maxWidth * 0.3,
                      decoration: BoxDecoration(
                        color: page.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.image,
                        size: constraints.maxWidth * 0.15,
                        color: page.color,
                      ),
                    ),

                    SizedBox(height: constraints.maxHeight * 0.05),

                    // Título
                    Text(
                      page.title,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: page.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),

                    SizedBox(height: constraints.maxHeight * 0.03),

                    // Descripción
                    Text(
                      page.description,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.04,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Configuración APN (solo si es necesario)
                    if (page.image == Icons.settings_cell) ...[
                      SizedBox(height: constraints.maxHeight * 0.03),
                      _buildResponsiveAPNConfig(constraints),
                    ],

                    // Espacio flexible
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveAPNConfig(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración APN:',
            style: TextStyle(
              fontSize: constraints.maxWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: constraints.maxHeight * 0.02),

          // Usar column o grid según el tamaño
          if (constraints.maxWidth < 400)
            _buildVerticalConfig()
          else
            _buildGridConfig(),
        ],
      ),
    );
  }

  Widget _buildVerticalConfig() {
    return Column(
      children: [
        _buildConfigRow('Nombre:', 'Desoft'),
        _buildConfigRow('APN:', 'desoft'),
        _buildConfigRow('Usuario:', 'desoft'),
        _buildConfigRow('Contraseña:', 'desoft'),
      ],
    );
  }

  Widget _buildGridConfig() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildConfigBox('Nombre', 'Desoft'),
        _buildConfigBox('APN', 'desoft'),
        _buildConfigBox('Usuario', 'desoft'),
        _buildConfigBox('Contraseña', 'desoft'),
      ],
    );
  }

  Widget _buildConfigBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: _currentPage == index ? 30 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _currentPage == index ? _pages[index].color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Guardar en SharedPreferences que ya vio el onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    // Llamar al callback para continuar
    widget.onComplete();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
\n```\n
\n## Archivo: lib/screen/directory/users_list_screen.dart\n```
// import 'package:flutter/material.dart';
// import '../../models/user.dart';
// import '../../providers/user_provider.dart';
// import './create_user_screen.dart';

// class UsersListScreen extends StatefulWidget {
//   const UsersListScreen({super.key});

//   @override
//   _UsersListScreenState createState() => _UsersListScreenState();
// }

// class _UsersListScreenState extends State<UsersListScreen> {
//   final UserProvider _userProvider = UserProvider();
//   String _filterRole = 'todos';

//   // List<String> get _filterOptions => ['todos', 'admin', 'consult'];

//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//   }

//   Future<void> _loadUsers() async {
//     await _userProvider.loadUsers();
//   }

//   Future<void> _refreshUsers() async {
//     await _userProvider.refreshUsers();
//   }

//   void _navigateToCreateUser() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const CreateUserScreen()),
//     ).then((_) => _refreshUsers());
//   }

//   List<User> get _filteredUsers {
//     if (_filterRole == 'todos') return _userProvider.users;
//     return _userProvider.users.where((user) {
//       return user.roles.any((role) => role.nombre == _filterRole);
//     }).toList();
//   }

//   Widget _buildUserCard(User user) {
//     final isAdmin = user.isAdmin;
//     final isConsult = user.isConsult;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: isAdmin
//               ? Colors.red[100]
//               : isConsult
//               ? Colors.green[100]
//               : Colors.grey[100],
//           child: Icon(
//             isAdmin
//                 ? Icons.admin_panel_settings
//                 : isConsult
//                 ? Icons.search
//                 : Icons.person,
//             color: isAdmin
//                 ? Colors.red[700]
//                 : isConsult
//                 ? Colors.green[700]
//                 : Colors.grey[700],
//           ),
//         ),
//         title: Text(
//           user.username,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(user.email),
//             const SizedBox(height: 4),
//             Wrap(
//               spacing: 4,
//               children: user.roles.map((role) {
//                 final isAdminRole = role.nombre == 'admin';
//                 final isConsultRole = role.nombre == 'consult';

//                 return Chip(
//                   label: Text(
//                     isAdminRole
//                         ? 'ADMIN'
//                         : isConsultRole
//                         ? 'CONSULTOR'
//                         : role.nombre.toUpperCase(),
//                     style: const TextStyle(fontSize: 10),
//                   ),
//                   backgroundColor: isAdminRole
//                       ? Colors.red[100]
//                       : isConsultRole
//                       ? Colors.green[100]
//                       : Colors.grey[100],
//                   labelStyle: TextStyle(
//                     color: isAdminRole
//                         ? Colors.red[800]
//                         : isConsultRole
//                         ? Colors.green[800]
//                         : Colors.grey[800],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final roleStats = _userProvider.getRoleStats();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Usuarios'),
//         backgroundColor: Colors.blue[700],
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshUsers),
//           IconButton(
//             icon: const Icon(Icons.person_add),
//             onPressed: _navigateToCreateUser,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filtros
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     initialValue: _filterRole,
//                     decoration: const InputDecoration(
//                       labelText: 'Filtrar por rol',
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     items: [
//                       DropdownMenuItem(
//                         value: 'todos',
//                         child: Row(
//                           children: [
//                             Icon(Icons.all_inclusive, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             const Text('Todos los roles'),
//                           ],
//                         ),
//                       ),
//                       DropdownMenuItem(
//                         value: 'admin',
//                         child: Row(
//                           children: [
//                             Icon(Icons.admin_panel_settings, color: Colors.red),
//                             const SizedBox(width: 8),
//                             const Text('Administradores'),
//                           ],
//                         ),
//                       ),
//                       DropdownMenuItem(
//                         value: 'user',
//                         child: Row(
//                           children: [
//                             Icon(Icons.person, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             const Text('Usuarios'),
//                           ],
//                         ),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         _filterRole = value!;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Estadísticas
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             color: Colors.grey[50],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       '${_filteredUsers.length}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const Text('Mostrados', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text(
//                       '${roleStats['admin'] ?? 0}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const Text(
//                       'Administradores',
//                       style: TextStyle(fontSize: 12),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text(
//                       '${roleStats['user'] ?? 0}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                     const Text('Usuarios', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Lista
//           Expanded(
//             child: _userProvider.loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : RefreshIndicator(
//                     onRefresh: _refreshUsers,
//                     child: _filteredUsers.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.group_off,
//                                   size: 64,
//                                   color: Colors.grey[300],
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   _filterRole == 'todos'
//                                       ? 'No hay usuarios registrados'
//                                       : 'No hay usuarios con este rol',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.grey[500],
//                                   ),
//                                 ),
//                                 if (_filterRole == 'todos')
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 16),
//                                     child: ElevatedButton.icon(
//                                       onPressed: _navigateToCreateUser,
//                                       icon: const Icon(Icons.person_add),
//                                       label: const Text('Crear primer usuario'),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             itemCount: _filteredUsers.length,
//                             itemBuilder: (context, index) =>
//                                 _buildUserCard(_filteredUsers[index]),
//                           ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
\n```\n
\n## Archivo: lib/screen/directory/workers_screen.dart\n```
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/local.dart';
import '../../models/worker.dart';
import '../../models/worker_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/local_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/call_service.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/worker_dialog.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  WorkersScreenState createState() => WorkersScreenState();
}

class WorkersScreenState extends State<WorkersScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filtro por departamento/área
  int? _selectedDepartmentId;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Variables para importación Excel
  String? _selectedExcelFilePath;
  List<Map<String, dynamic>> _previewData = [];
  bool _isProcessingExcel = false;

  @override
  void initState() {
    super.initState();

    // Search con debounce optimizado
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _onSearchChanged);
    });

    // Scroll listener para paginación
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).clearSearch();
      _loadInitialData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      Provider.of<WorkerProvider>(
        context,
        listen: false,
      ).searchWorkers(_searchController.text);
    }
  }

  void _loadInitialData() {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);

    workerProvider.loadInitialData();

    if (!departmentProvider.hasLoaded) {
      departmentProvider.loadDepartments();
    }
    if (!localProvider.hasLoaded) {
      localProvider.loadLocals();
    }
  }

  Future<void> _loadMoreData() async {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    if (workerProvider.isLoadingMore || !workerProvider.hasMore) {
      return;
    }

    final success = await workerProvider.loadMoreWorkers();

    if (success && mounted) {
      if (workerProvider.hasMore) {
        _showSnackBar('Cargando más trabajadores...');
      }
    }
  }

  // ============ MÉTODOS DE UI ============

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _safeDialogSetState(StateSetter setState, VoidCallback update) {
    try {
      setState(update);
    } catch (_) {}
  }

  // ============ MÉTODOS DE AGREGAR TRABAJADORES ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddWorkerOptions,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue[700],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  // Mostrar opciones de agregar
  void _showAddWorkerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Agregar Trabajadores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Selecciona cómo deseas agregar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Opción: Agregar manual
              _buildOptionCard(
                icon: Icons.person_add,
                title: 'Agregar Manual',
                subtitle: 'Ingresar datos uno por uno',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showAddWorkerDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples trabajadores desde archivo .xlsx',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Widget para cada opción
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ============ DIÁLOGO DE IMPORTACIÓN EXCEL ============

  void _showExcelImportDialog() {
    _selectedExcelFilePath = null;
    _previewData = [];
    _isProcessingExcel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Importar Excel'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un archivo Excel (.xlsx) con la estructura requerida',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // Área de selección de archivo
                    GestureDetector(
                      onTap: _isProcessingExcel
                          ? null
                          : () => _pickExcelFile(setState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedExcelFilePath != null
                                ? Colors.green
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedExcelFilePath != null
                              ? Colors.green[50]
                              : Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedExcelFilePath != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: _selectedExcelFilePath != null
                                  ? Colors.green
                                  : Colors.green[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedExcelFilePath != null
                                  ? _selectedExcelFilePath!.split('/').last
                                  : 'Toca para seleccionar archivo',
                              style: TextStyle(
                                color: _selectedExcelFilePath != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontWeight: _selectedExcelFilePath != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedExcelFilePath == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Formatos soportados: .xlsx, .xls',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descargar plantilla
                    InkWell(
                      onTap: _downloadExcelTemplate,
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_download,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessingExcel) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Procesando archivo...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Previsualización de datos
                    if (_previewData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                itemCount: _previewData.length > 5
                                    ? 5
                                    : _previewData.length,
                                itemBuilder: (context, index) {
                                  final item = _previewData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${index + 1}. ${item['nombre'] ?? 'Sin nombre'} - ${item['carnet'] ?? 'Sin carnet'}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessingExcel
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isProcessingExcel || _selectedExcelFilePath == null
                      ? null
                      : () => _processExcelFile(context, setState),
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Seleccionar archivo Excel
  Future<void> _pickExcelFile(StateSetter setState) async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para importar archivos.',
            isError: true,
          );
          return;
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        _safeDialogSetState(setState, () {
          _selectedExcelFilePath = result.files.single.path;
          _previewData = [];
        });

        await _previewExcelFile(result.files.single.path!, setState);
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar archivo: $e', isError: true);
    }
  }

  // Previsualizar archivo Excel
  Future<void> _previewExcelFile(String filePath, StateSetter setState) async {
    try {
      final rows = await ExcelImportService.readRowsFromFile(filePath);
      final parsedRows = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: [
          'nombre',
          'apellido',
          'carnet',
          'telefono',
          'direccion',
          'departamento',
          'local',
          'fechacumpleannos',
        ],
      );

      if (parsedRows.isEmpty) {
        throw Exception('No se encontraron registros válidos en el archivo.');
      }

      _safeDialogSetState(setState, () {
        _previewData = parsedRows;
      });
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      _safeDialogSetState(setState, () {
        _selectedExcelFilePath = null;
        _previewData = [];
      });
    }
  }

  // Procesar archivo Excel
  Future<void> _processExcelFile(
    BuildContext context,
    StateSetter setState,
  ) async {
    if (_selectedExcelFilePath == null || _previewData.isEmpty) {
      _showSnackBar('No hay datos para importar', isError: true);
      return;
    }

    _safeDialogSetState(setState, () {
      _isProcessingExcel = true;
    });

    try {
      final workerProvider = Provider.of<WorkerProvider>(
        context,
        listen: false,
      );
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

      int successCount = 0;
      int skippedCount = 0;

      for (final data in _previewData) {
        try {
          final rawName = data['nombre']?.toString().trim() ?? '';
          final rawLastName = data['apellido']?.toString().trim() ?? '';
          final carnetID = data['carnet']?.toString().trim() ?? '';
          final phone = data['telefono']?.toString().trim() ?? '';
          final address = data['direccion']?.toString().trim() ?? '';
          final birthday = data['fechacumpleannos']?.toString().trim() ?? '';

          final nameParts = rawName.split(RegExp(r'\s+'));
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : rawLastName;

          Department? department;
          if (data['departamento'] != null &&
              data['departamento'].toString().isNotEmpty) {
            final deptName = data['departamento'].toString().trim();
            try {
              final dept = departmentProvider.departments.firstWhere(
                (d) => d.name.toLowerCase() == deptName.toLowerCase(),
              );
              department = Department(
                id: dept.id,
                name: dept.name,
                phone: dept.phone,
              );
            } catch (_) {}
          }

          Local? local;
          if (data['local'] != null && data['local'].toString().isNotEmpty) {
            final localName = data['local'].toString().trim();
            try {
              final loc = localProvider.locals.firstWhere(
                (l) => l.name.toLowerCase() == localName.toLowerCase(),
              );
              local = Local(id: loc.id, name: loc.name, phone: loc.phone);
            } catch (_) {}
          }

          if (firstName.isEmpty || carnetID.isEmpty) {
            skippedCount++;
            continue;
          }

          final success = await workerProvider.createWorker(
            Worker(
              id: 0,
              name: firstName,
              lastName: lastName,
              carnetID: carnetID,
              phone: phone,
              address: address,
              fechaCumpleannos: birthday,
              department: department,
              local: local,
              cumpleannoId: null,
            ),
          );

          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (_) {
          skippedCount++;
        }
      }

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      if (successCount > 0) {
        _showSnackBar(
          '✅ $successCount trabajadores importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await workerProvider.refreshWorkers();
      } else {
        _showSnackBar(
          '❌ No se pudo importar ningún trabajador${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      _showSnackBar('❌ Error al importar: ${e.toString()}', isError: true);
    } finally {
      _safeDialogSetState(setState, () {
        _isProcessingExcel = false;
      });
    }
  }

  // Descargar plantilla de ejemplo
  Future<void> _downloadExcelTemplate() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para descargar archivos.',
            isError: true,
          );
          return;
        }
      }

      _showSnackBar('📥 Generando plantilla...');
      final filePath = await ExcelTemplateService.generateWorkersTemplate();
      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        _showSnackBar('✅ Plantilla lista en: $filePath');
      } else {
        _showSnackBar('❌ No se pudo generar la plantilla', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '❌ Error al generar plantilla: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ============ MÉTODOS DE MANEJO DE TRABAJADORES ============

  void _showAddWorkerDialog() {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar trabajadores',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WorkerDialog(
        onSave: (worker) => _handleCreateWorker(worker, workerProvider),
        departmentProvider: departmentProvider,
        localProvider: localProvider,
      ),
    );
  }

  Future<bool> _handleCreateWorker(
    Worker worker,
    WorkerProvider provider,
  ) async {
    debugPrint('[WorkersScreen][CREATE] Starting create: ${worker.toJson()}');
    final success = await provider.createWorker(worker);
    debugPrint(
      '[WorkersScreen][CREATE] Finished success=$success error="${provider.error}"',
    );

    if (mounted) {
      if (success) {
        _showSnackBar('✅ Trabajador creado exitosamente');
      } else {
        _showSnackBar('❌ Error: ${provider.error}', isError: true);
      }
    }

    return success;
  }

  void _showEditWorkerDialog(Worker worker) {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para editar trabajadores',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WorkerDialog(
        worker: worker,
        onSave: (updatedWorker) =>
            _handleUpdateWorker(worker.id, updatedWorker, workerProvider),
        departmentProvider: departmentProvider,
        localProvider: localProvider,
      ),
    );
  }

  Future<bool> _handleUpdateWorker(
    int workerId,
    Worker updatedWorker,
    WorkerProvider provider,
  ) async {
    final worker = updatedWorker.copyWith(id: workerId);
    debugPrint('[WorkersScreen][EDIT] Starting update: ${worker.toJson()}');
    final success = await provider.updateWorker(worker);
    debugPrint(
      '[WorkersScreen][EDIT] Finished success=$success error="${provider.error}"',
    );

    if (mounted) {
      if (success) {
        _showSnackBar('✅ Trabajador actualizado exitosamente');
      } else {
        _showSnackBar('❌ Error: ${provider.error}', isError: true);
      }
    }

    return success;
  }

  void _showDeleteConfirmation(Worker worker) {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar trabajadores',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(child: const Text('Eliminar Trabajador')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 40,
              child: Icon(Icons.person, size: 40, color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar a:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              worker.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Carnet: ${worker.carnetID}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _handleDeleteWorker(worker.id, workerProvider),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteWorker(
    int workerId,
    WorkerProvider provider,
  ) async {
    if (!mounted) return;

    Navigator.of(context).pop();

    _showSnackBar('⏳ Eliminando trabajador...');

    final success = await provider.deleteWorker(workerId);

    if (success) {
      _showSnackBar('🗑️ Trabajador eliminado exitosamente');
    } else {
      _showSnackBar('❌ Error: ${provider.error}', isError: true);
    }
  }

  Future<void> _syncWorkers(WorkerProvider provider) async {
    final success = await provider.syncWorkers();

    if (success) {
      _showSnackBar('✅ Sincronización completada');
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  // ============ MÉTODOS DE DETALLES ============

  void _showWorkerDetails(Worker worker, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle para arrastrar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header con avatar
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          worker.initials,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      worker.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carnet: ${worker.carnetID}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey[200]),

              // Información detallada
              _buildDetailSection(
                icon: Icons.phone,
                label: 'Teléfono',
                value: worker.phone.isNotEmpty ? worker.phone : 'No disponible',
                color: Colors.blue[700]!,
              ),

              if (worker.address.isNotEmpty)
                _buildDetailSection(
                  icon: Icons.home,
                  label: 'Dirección',
                  value: worker.address,
                  color: Colors.green[700]!,
                ),

              if (worker.hasBirthday)
                _buildDetailSection(
                  icon: Icons.cake,
                  label: 'Fecha de Cumpleaños',
                  value: worker.formattedBirthday,
                  color: Colors.pink[700]!,
                ),

              if (worker.hasDepartment)
                _buildClickableDetail(
                  icon: Icons.work,
                  label: 'Departamento',
                  value: worker.department!.name,
                  color: Colors.orange[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showDepartmentDetails(worker.department!.id);
                  },
                ),

              if (worker.hasLocal)
                _buildClickableDetail(
                  icon: Icons.business,
                  label: 'Local',
                  value: worker.local!.name,
                  color: Colors.green[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showLocalDetails(worker.local!.id);
                  },
                ),

              const SizedBox(height: 20),

              // Acciones de contacto
              if (worker.phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactAction(
                        Icons.phone,
                        'Llamar',
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _makePhoneCall(worker.phone);
                        },
                      ),
                      _buildContactAction(
                        Icons.copy,
                        'Copiar',
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _copyPhoneNumber(worker.phone);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditWorkerDialog(worker);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(worker);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkerDetailsFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showWorkerDetails(worker, isAdmin);
    } else {
      _showSnackBar('Error al cargar detalles', isError: true);
    }
  }

  void _showActionMenuFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para esta acción', isError: true);
      return;
    }

    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showActionMenu(worker);
    }
  }

  void _showActionMenu(Worker worker) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditWorkerDialog(worker);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(worker);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(WorkerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: provider.isLoadingMore
          ? CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            )
          : Text(
              'Toque para cargar más',
              style: TextStyle(color: Colors.grey[600]),
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[700]),
          const SizedBox(height: 16),
          Text(
            'Cargando trabajadores...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WorkerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isOffline ? Icons.cloud_off : Icons.error_outline,
            size: 64,
            color: provider.isOffline ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            provider.isOffline
                ? 'Modo offline'
                : 'Error al cargar trabajadores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.isOffline && provider.hasLocalData
                  ? 'Mostrando ${provider.localDataCount} trabajadores almacenados localmente.'
                  : provider.error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),

          if (provider.isOffline && provider.hasLocalData)
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text(
                    'Sincronizar ahora',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _syncWorkers(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => provider.loadWorkers(),
                  child: const Text('Continuar en modo offline'),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => provider.loadWorkers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAdmin, WorkerProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchController.text.isEmpty
                    ? Icons.people_outline
                    : Icons.search_off,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay trabajadores registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchController.text.isEmpty
                    ? ''
                    : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (isAdmin && _searchController.text.isEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Agregar Primer Trabajador',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _showAddWorkerOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).clearSearch();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCardLite(WorkerLite worker, bool isAdmin) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showWorkerDetailsFromLite(worker, isAdmin),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 20,
                child: Text(
                  worker.initials,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      worker.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (worker.hasPhone) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              worker.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showActionMenuFromLite(worker, isAdmin),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 16, color: color),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: color, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentDetails(int departmentId) async {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );

    final department = await departmentProvider.getDepartmentById(departmentId);

    if (department == null) {
      _showSnackBar('Departamento no encontrado', isError: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline,
                  size: 40,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                department.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (department.phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', department.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (department.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Llamar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(department.phone);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLocalDetails(int localId) async {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);

    final local = await localProvider.getLocalById(localId);

    if (local == null) {
      _showSnackBar('Local no encontrado', isError: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_outlined,
                  size: 40,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                local.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (local.phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', local.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (local.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Llamar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(local.phone);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildContactAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============ MÉTODOS DE CONTACTO ============

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return;
    }
    _showSnackBar('📞 Llamando a $phoneNumber...');

    try {
      await CallService.directCall(phoneNumber);
    } catch (e) {
      _showSnackBar('❌ Error al iniciar llamada');
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.of(context).pop();

    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
        .then((value) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Número copiado: $cleanPhoneNumber'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al copiar el número'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
  }

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Trabajadores',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.blue[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<WorkerProvider>(
              builder: (context, provider, child) {
                if (provider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: provider.isOffline ? Colors.orange : Colors.white,
                    size: 24,
                  ),
                  onPressed: provider.isOffline
                      ? () => _syncWorkers(provider)
                      : null,
                  tooltip: provider.isOffline
                      ? 'Modo offline - Toque para sincronizar'
                      : 'En línea',
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                workerProvider.loadWorkers(forceRefresh: true);
                _showSnackBar('🔄 Actualizando lista...');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        // body: _buildBody(workerProvider, isAdmin),
        body: Stack(
          children: [
            _buildBody(workerProvider, isAdmin),

            if (workerProvider.loading && workerProvider.hasLoaded) ...[
              const ModalBarrier(dismissible: false, color: Colors.black54),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      "🔄 Actualizando lista...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBody(WorkerProvider workerProvider, bool isAdmin) {
    if (workerProvider.loading && !workerProvider.hasLoaded) {
      return _buildLoadingIndicator();
    }

    if (workerProvider.hasError && !workerProvider.hasLoaded) {
      return _buildErrorState(workerProvider);
    }

    final visibleWorkers = workerProvider.visibleWorkers;

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, carnet o teléfono...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<WorkerProvider>(
                            context,
                            listen: false,
                          ).clearSearch();
                        },
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),

        Consumer<DepartmentProvider>(
          builder: (context, departmentProvider, _) {
            return _buildDepartmentFilter(departmentProvider);
          },
        ),

        // Contador optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Consumer<WorkerProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        '${visibleWorkers.length} de ${provider.totalWorkers}${provider.isOffline ? ' (offline)' : ''}',
                        style: TextStyle(
                          color: provider.isOffline
                              ? Colors.orange[700]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Consumer<WorkerProvider>(
                builder: (context, provider, child) {
                  if (provider.isOffline) {
                    return _buildStatusBadge('Offline', Colors.orange);
                  }
                  if (_searchController.text.isNotEmpty) {
                    return _buildStatusBadge('Búsqueda activa', Colors.blue);
                  }
                  if (provider.hasMore) {
                    return _buildStatusBadge('Más disponible', Colors.green);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Lista con paginación
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await workerProvider.refreshWorkers();
              _showSnackBar('✅ Lista actualizada');
            },
            color: Colors.blue[700],
            child: visibleWorkers.isEmpty
                ? _buildEmptyState(isAdmin, workerProvider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        visibleWorkers.length +
                        (workerProvider.hasMore ? 1 : 0),
                    itemExtent: 80,
                    itemBuilder: (context, index) {
                      if (index >= visibleWorkers.length) {
                        return _buildLoadMoreIndicator(workerProvider);
                      }

                      final workerLite = visibleWorkers[index];
                      return _buildWorkerCardLite(workerLite, isAdmin);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentFilter(DepartmentProvider departmentProvider) {
    final departments = departmentProvider.departments;
    if (departments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Todos'),
                selected: _selectedDepartmentId == null,
                onSelected: (_) {
                  setState(() => _selectedDepartmentId = null);
                  Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).filterByDepartment(null);
                },
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[700],
                labelStyle: TextStyle(
                  color: _selectedDepartmentId == null
                      ? Colors.blue[700]
                      : Colors.grey[700],
                  fontWeight: _selectedDepartmentId == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedDepartmentId == null
                        ? Colors.blue[700]!
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            ...departments.map((dept) {
              final isSelected = _selectedDepartmentId == dept.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(dept.name),
                  selected: isSelected,
                  onSelected: (_) {
                    final newValue = isSelected ? null : dept.id;
                    setState(() => _selectedDepartmentId = newValue);
                    Provider.of<WorkerProvider>(
                      context,
                      listen: false,
                    ).filterByDepartment(newValue);
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[700] : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.blue[700]!
                          : Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/screen/setting/config_screen.dart\n```
import 'package:flutter/material.dart';
import '../../screen/directory/home_screen.dart';
import 'package:provider/provider.dart';
import '../../models/rol.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../auth/login_screen.dart';
import 'network_config_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  bool _notifications = true;
  String _appVersion = '1.0.0';
  final bool _updateAvailable = false;
  late User? _currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _cacheInfo = {};
  bool _loadingCacheInfo = false;
  bool _checkingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppInfo();
    _loadCacheInfo();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        await authProvider.checkAuthStatus();
      }

      setState(() {
        _currentUser = authProvider.user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final updateService = ServiceLocator().updateService;
      final currentVersion = await updateService.getCurrentVersion();

      setState(() {
        _appVersion = currentVersion;
      });
    } catch (e) {
      debugPrint('Error al cargar información de la app: $e');
    }
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _loadingCacheInfo = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final info = await authProvider.getCacheInfo();

      setState(() {
        _cacheInfo = info;
        _loadingCacheInfo = false;
      });
    } catch (e) {
      setState(() {
        _cacheInfo = {'total': 0, 'items': 0, 'details': {}, 'categories': {}};
        _loadingCacheInfo = false;
      });
    }
  }

  void _showUserInfo() {
    final user = _currentUser ?? _getExampleUser();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Información del Usuario',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Usuario:', user.username),
            _buildInfoRow('Email:', user.email),
            _buildInfoRow('Rol:', user.isAdmin ? 'Administrador' : 'Consultor'),
            _buildInfoRow(
              'Registrado:',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isAdmin
                    ? '🔐 Este usuario tiene permisos de administrador'
                    : '👁️ Este usuario tiene permisos de consulta',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  User _getExampleUser() {
    return User(
      id: 0,
      username: 'Usuario',
      email: 'usuario@ejemplo.com',
      password: '',
      roles: [Rol(id: 2, nombre: 'consult')],
      createdAt: DateTime.now(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Acerca de'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Directorio de Trabajadores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplicación para la gestión y consulta de información laboral.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildAboutInfo('Versión', _appVersion),
            _buildAboutInfo('Desarrollador', 'Desoft Cuba'),
            _buildAboutInfo('Año', '2024'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '© Todos los derechos reservados. '
                'Esta aplicación es para uso interno.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Política de Privacidad',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Protección de Datos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• La información personal se maneja de forma confidencial.\n'
                '• Solo el personal autorizado tiene acceso a los datos.\n'
                '• Los datos no se comparten con terceros.\n'
                '• Se implementan medidas de seguridad adecuadas.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Términos de Uso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• Uso exclusivo para fines laborales.\n'
                '• Prohibido compartir credenciales.\n'
                '• Reportar actividades sospechosas.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateService = ServiceLocator().updateService;

      final updateInfo = await updateService.checkUpdates(
        forceCheck: true,
        showNotification: false,
      );

      if (updateInfo != null) {
        // Esperar un poco para que el botón cambie de estado
        await Future.delayed(const Duration(milliseconds: 300));
        // ✅ Llamar al método de descarga
        if (!mounted) return;

        await updateService.downloadUpdate(updateInfo, context);

        // Mostrar mensaje de éxito (pero no actualizar la versión automáticamente)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Actualización descargada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // No hay actualizaciones
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ya tienes la última versión'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ ConfigScreen Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              setState(() {
                _currentUser = null;
              });
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCacheInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Información de Almacenamiento Local',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: _loadingCacheInfo
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCacheInfoRow(
                    '💾 Uso total:',
                    _formatBytes(_cacheInfo['total'] ?? 0),
                  ),
                  _buildCacheInfoRow(
                    '📁 Archivos:',
                    '${_cacheInfo['items'] ?? 0}',
                  ),

                  if (_cacheInfo['categories'] != null &&
                      (_cacheInfo['categories'] as Map).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '📊 Por categorías:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._buildCategoryDetails(),
                      ],
                    ),

                  if (_cacheInfo['details'] != null &&
                      (_cacheInfo['details'] as Map).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '📋 Detalles por archivo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: SingleChildScrollView(
                            child: Column(children: _buildCacheDetails()),
                          ),
                        ),
                      ],
                    ),

                  if ((_cacheInfo['details'] == null ||
                          (_cacheInfo['details'] as Map).isEmpty) &&
                      (_cacheInfo['categories'] == null ||
                          (_cacheInfo['categories'] as Map).isEmpty))
                    const Text('📭 No hay datos almacenados localmente'),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showClearCacheOptions();
            },
            child: const Text(
              'Gestionar',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryDetails() {
    final categories = _cacheInfo['categories'] as Map<String, dynamic>?;
    if (categories == null || categories.isEmpty) return [];

    return categories.entries
        .map((entry) {
          if (entry.value > 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('• ${_getCategoryName(entry.key)}:'),
                  Text(_formatBytes(entry.value as int)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        })
        .where((widget) => widget != const SizedBox.shrink())
        .toList();
  }

  String _getCategoryName(String key) {
    switch (key) {
      case 'shared_preferences':
        return 'Preferencias';
      case 'cache_files':
        return 'Archivos Cache';
      case 'database':
        return 'Base de datos';
      default:
        return key;
    }
  }

  List<Widget> _buildCacheDetails() {
    final details = _cacheInfo['details'] as Map<String, dynamic>?;
    if (details == null || details.isEmpty) return [const SizedBox()];

    final entries = details.entries.toList();

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '• ${entry.key}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatBytes(entry.value as int),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showClearCacheOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text('Opciones de Limpieza', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona qué quieres limpiar:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Limpiar Cache Temporal'),
              subtitle: const Text(
                'Archivos temporales, sin afectar datos principales',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showClearCacheConfirmation(tipo: 'cache');
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Eliminar Todos los Datos'),
              subtitle: const Text(
                'Base de datos completa, archivos y preferencias',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showClearAllDataConfirmation();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation({String tipo = 'cache'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Borrar Caché'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres borrar la caché?'),
            const SizedBox(height: 12),
            const Text(
              'Esto eliminará:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Archivos temporales'),
            const Text('• Datos cache del sistema'),
            const Text('• Configuraciones temporales'),
            if (tipo == 'all')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• Base de datos local'),
                  const Text('• Preferencias guardadas'),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tipo == 'cache'
                    ? '⚠️ No se eliminarán tus datos principales.'
                    : '⚠️ La aplicación se reiniciará y perderás toda la información local.',
                style: TextStyle(color: Colors.orange[800], fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache(tipo: tipo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tipo == 'cache' ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(tipo == 'cache' ? 'Limpiar Cache' : 'Eliminar Todo'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '⚠️ Eliminar Todos los Datos',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta acción eliminará:'),
            const SizedBox(height: 12),
            const Text('• Base de datos completa'),
            const Text('• Todos los archivos cache'),
            const Text('• Preferencias de la aplicación'),
            const Text('• Configuraciones guardadas'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ La aplicación se reiniciará y perderás toda la información local.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache(tipo: 'all');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache({String tipo = 'cache'}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Procesando...'),
            ],
          ),
        ),
      ),
    );

    try {
      bool success;

      if (tipo == 'cache') {
        success = await authProvider.clearAppCache();
      } else {
        success = await authProvider.clearAllData();
      }

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tipo == 'cache'
                    ? '✅ Caché borrada exitosamente'
                    : '✅ Todos los datos fueron eliminados',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await _loadCacheInfo();
          await _loadUserData();

          if (tipo != 'cache' && !authProvider.isAuthenticated && mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al procesar la solicitud'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.blue[50],
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            _currentUser != null && _currentUser!.isAdmin
                                ? Icons.admin_panel_settings
                                : _currentUser != null
                                ? Icons.person
                                : Icons.person_outline,
                            size: 30,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.username ?? 'Invitado',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _currentUser?.email ?? 'Modo de solo lectura',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  _currentUser != null
                                      ? (_currentUser!.isAdmin
                                            ? 'Administrador'
                                            : 'Consultor')
                                      : 'Invitado',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor:
                                    _currentUser != null &&
                                        _currentUser!.isAdmin
                                    ? Colors.red[100]
                                    : Colors.green[100],
                                labelStyle: TextStyle(
                                  color:
                                      _currentUser != null &&
                                          _currentUser!.isAdmin
                                      ? Colors.red[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentUser != null)
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                            ),
                            onPressed: _showUserInfo,
                            tooltip: 'Ver información',
                          ),
                        IconButton(
                          icon: Icon(
                            _currentUser != null ? Icons.logout : Icons.login,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (_currentUser != null) {
                              _showLogoutConfirmation();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          tooltip: _currentUser != null
                              ? 'Cerrar sesión'
                              : 'Iniciar sesión',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'PREFERENCIAS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Notificaciones'),
                          subtitle: const Text(
                            'Recibir notificaciones importantes',
                          ),
                          value: _notifications,
                          onChanged: (value) {
                            setState(() {
                              _notifications = value;
                            });
                          },
                          activeThumbColor: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'ALMACENAMIENTO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.storage,
                            color: Colors.blue,
                          ),
                          title: const Text('Información de Caché'),
                          subtitle: _loadingCacheInfo
                              ? const Text('Calculando...')
                              : Text(
                                  '${_cacheInfo['items'] ?? 0} items • ${_formatBytes(_cacheInfo['total'] ?? 0)}',
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showCacheInfoDialog,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          title: const Text('Borrar Caché'),
                          subtitle: const Text(
                            'Eliminar datos almacenados localmente',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showClearCacheOptions(),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'INFORMACIÓN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.blue),
                          title: const Text('Acerca de'),
                          subtitle: const Text('Información de la aplicación'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.security,
                            color: Colors.blue,
                          ),
                          title: const Text('Privacidad y Términos'),
                          subtitle: const Text('Políticas de uso y privacidad'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showPrivacyPolicy,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.settings_cell,
                            color: Colors.blue,
                          ),
                          title: const Text('Configuración de Red'),
                          subtitle: const Text(
                            'Configuración APN y conexión corporativa',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NetworkConfigScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'ACTUALIZACIONES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.update,
                        color: _updateAvailable ? Colors.green : Colors.blue,
                      ),
                      title: const Text('Versión de la App'),
                      subtitle: Text('Versión $_appVersion'),
                      trailing: _updateAvailable
                          ? const Chip(
                              label: Text('NUEVO'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _checkingForUpdates ? null : _checkForUpdates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: _checkingForUpdates
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _updateAvailable
                                  ? Icons.download
                                  : Icons.system_update,
                              size: 24,
                            ),
                      label: Text(
                        _checkingForUpdates
                            ? 'VERIFICANDO...'
                            : _updateAvailable
                            ? 'DESCARGAR ACTUALIZACIÓN'
                            : 'BUSCAR ACTUALIZACIONES',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 0, 106, 152),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.near_me,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: Color(0xFF444650),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Directorio Telefónico © 2025',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF444650),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
\n```\n
\n## Archivo: lib/screen/setting/network_config_screen.dart\n```
import 'package:flutter/material.dart';

class NetworkConfigScreen extends StatelessWidget {
  const NetworkConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración de Red',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
            _buildHeaderSection(),

            const SizedBox(height: 24),

            // Línea corporativa
            _buildCorporateLineSection(),

            const SizedBox(height: 24),

            // Configuración APN
            _buildAPNConfigSection(),

            const SizedBox(height: 24),

            // Consideraciones importantes
            _buildImportantNotesSection(),

            const SizedBox(height: 32),

            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_cell, size: 40, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Red Corporativa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sigue estos pasos para configurar correctamente '
                  'la conexión a la red de Desoft',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorporateLineSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  'Línea Corporativa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Propósito:',
              'Conexión dedicada para el uso del Directorio Telefónico',
              Icons.info,
            ),
            _buildInfoItem(
              'Requisito:',
              'Dispositivo corporativo o autorizado',
              Icons.security,
            ),
            _buildInfoItem(
              'Alcance:',
              'Acceso a datos internos de la empresa',
              Icons.network_check,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta configuración es exclusiva para uso corporativo',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPNConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sim_card, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(
                  'Configuración APN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Paso 1
            _buildStepItem(
              1,
              'Ajustes > Conexiones > Redes móviles',
              Icons.settings,
            ),

            // Paso 2
            _buildStepItem(2, 'Nombres de punto de acceso (APN)', Icons.add),

            // Paso 3
            _buildStepItem(
              3,
              'Agregar nuevo APN o editar existente',
              Icons.edit,
            ),

            const SizedBox(height: 16),

            // Configuración específica
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parámetros de configuración:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildConfigItem('Nombre:', 'Desoft'),
                  _buildConfigItem('APN:', 'desoft'),
                  _buildConfigItem('Nombre de usuario:', 'desoft'),
                  _buildConfigItem('Contraseña:', 'desoft'),
                  _buildConfigItem('Autenticación:', 'PAP o CHAP'),
                  _buildConfigItem('Tipo de APN:', 'default,supl'),

                  const SizedBox(height: 8),
                  Divider(color: Colors.green[200]),
                  const SizedBox(height: 8),

                  _buildConfigItem('Proxy:', 'No configurar'),
                  _buildConfigItem('Puerto:', 'No configurar'),
                  _buildConfigItem('MMSC:', 'No configurar'),
                  _buildConfigItem('MCC:', 'Según país'),
                  _buildConfigItem('MNC:', 'Según operador'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.important_devices, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Consideraciones importantes',
                    softWrap: true,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildNoteItem(
              '🔒 Seguridad',
              'Esta configuración es para uso interno exclusivo de Desoft.',
            ),

            _buildNoteItem(
              '📶 Conexión',
              'Verificar que el dispositivo tenga cobertura de red corporativa.',
            ),

            _buildNoteItem(
              '⚙️ Compatibilidad',
              'Configuración válida para Android e iOS (con variaciones menores).',
            ),

            _buildNoteItem(
              '🔄 Actualización',
              'Los parámetros pueden cambiar según actualizaciones de infraestructura.',
            ),

            _buildNoteItem(
              '📞 Soporte',
              'Contactar al departamento de TI para problemas de conexión.',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No compartir estas credenciales fuera de la organización',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            _showSupportInfo(context);
          },
          child: const Text(
            '¿Necesitas ayuda? Contacta a Soporte Técnico',
            style: TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Widgets auxiliares
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String instruction, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String iconText, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(iconText, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('Soporte Técnico'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Departamento de Tecnologías de la Información',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('📞 Teléfono: 123-456-7890'),
              Text('📧 Email: soporte.ti@desoft.cu'),
              Text('🏢 Oficina: Edificio Central, Piso 3'),
              SizedBox(height: 12),
              Text(
                'Horario de atención:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Lunes a Viernes: 8:00 AM - 5:00 PM'),
              Text('Sábados: 8:00 AM - 12:00 PM'),
              SizedBox(height: 12),
              Text(
                'Problemas comunes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• No se conecta a la red corporativa'),
              Text('• Error de autenticación'),
              Text('• Datos móviles no funcionan'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/services/api/api_client.dart\n```
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/error_messages.dart';
import 'api_response.dart';

class ApiClient {
  static const Duration timeout = Duration(seconds: 30);

  final String baseUrl;
  String? token;
  final http.Client _client = http.Client();

  ApiClient({required this.baseUrl, this.token});

  // Método para actualizar el token
  void updateToken(String? newToken) {
    token = newToken;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // ✅ CAMBIADO: Solo agregar Authorization si token NO es null
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Método genérico para manejar todas las respuestas
  Future<ApiResponse<T>> _handleResponse<T>(
    Future<http.Response> request,
    T Function(dynamic)? fromJson,
  ) async {
    try {
      final response = await request.timeout(timeout);

      // Si la respuesta es exitosa (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          if (response.body.isEmpty) {
            return ApiResponse.success(
              null as T,
              statusCode: response.statusCode,
            );
          }

          final decoded = json.decode(response.body);

          // Si hay un fromJson, convertir, si no, devolver el JSON crudo
          final data = fromJson != null ? fromJson(decoded) : decoded as T;

          return ApiResponse.success(data, statusCode: response.statusCode);
        } catch (e) {
          return ApiResponse.error(
            ErrorMessages.dataProcessingError,
            technicalError: 'JSON Parse Error: $e\nResponse: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }

      // Si hay error del servidor
      return _handleErrorResponse(response);
    } on FormatException catch (e) {
      return ApiResponse.fromException(e);
    } on http.ClientException catch (e) {
      return ApiResponse.fromException(e.message);
    } on Exception catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Manejar errores HTTP específicos
  ApiResponse<T> _handleErrorResponse<T>(http.Response response) {
    try {
      final errorJson = json.decode(response.body);
      final serverMessage =
          errorJson['message']?.toString() ?? errorJson['error']?.toString();

      return ApiResponse.error(
        serverMessage ?? ErrorMessages.fromStatusCode(response.statusCode),
        technicalError: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Si no se puede parsear el error del servidor
      return ApiResponse.fromHttpError(response.statusCode);
    }
  }

  // MÉTODOS HTTP MEJORADOS - Ahora devuelven ApiResponse<T>

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = _getHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    final request = _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    return await _handleResponse<T>(request, fromJson);
  }

  void dispose() {
    _client.close();
  }
}
\n```\n
\n## Archivo: lib/services/api/api_endpoints.dart\n```
class ApiEndpoints {
  static const String baseUrl = 'http://directorio.scu.desoft.cu/backend';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/nuevo';
  static const String refreshToken = '/auth/refresh-token';
  static const String refresh = '/auth/refresh';

  // Users
  static const String users = '/usuario';
  static String userById(int id) => '/usuario/$id';

  // Roles
  static const String roles = '/rol';
  static String roleById(int id) => '/rol/$id';

  // Workers
  static const String workers = '/trabajador';
  static String workerById(int id) => '/trabajador/$id';
  static const String workerSearch = '/trabajador?search=';

  // Departments
  static const String departments = '/departamento';
  static String departmentById(int id) => '/departamento/$id';

  // local
  static const String local = '/local';
  static String localById(int id) => '/local/$id';

  // Efemerides
  static const String efemerides = '/efemeride';
  static String efemerideById(int id) => '/efemeride/$id';

  // Cumpleaños
  static const String birthdays = '/cumpleanno';
  static String birthdayById(int id) => '/cumpleanno/$id';
}
\n```\n
\n## Archivo: lib/services/api/api_response.dart\n```
// class ApiResponse<T> {
//   final T? data;
//   final String? error;
//   final bool success;

//   ApiResponse({this.data, this.error, required this.success});

//   factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);

//   factory ApiResponse.error(String error) =>
//       ApiResponse(success: false, error: error);

//   bool get hasError => !success;
//   bool get hasData => success && data != null;

//   @override
//   String toString() {
//     return 'ApiResponse{success: $success, data: $data, error: $error}';
//   }
// }

import '../../utils/error_messages.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final String? technicalError; // Para debug, no mostrar al usuario
  final bool success;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.error,
    this.technicalError,
    this.statusCode,
    required this.success,
  });

  factory ApiResponse.success(T data, {int? statusCode}) =>
      ApiResponse(success: true, data: data, statusCode: statusCode);

  factory ApiResponse.error(
    String error, {
    String? technicalError,
    int? statusCode,
  }) => ApiResponse(
    success: false,
    error: error,
    technicalError: technicalError,
    statusCode: statusCode,
  );

  bool get hasError => !success;
  bool get hasData => success && data != null;

  // Método útil para crear respuestas con mensajes amigables
  factory ApiResponse.fromException(dynamic exception, {int? statusCode}) {
    final friendlyMessage = ErrorMessages.fromException(exception);
    return ApiResponse.error(
      friendlyMessage,
      technicalError: exception.toString(),
      statusCode: statusCode,
    );
  }

  // Método útil para crear respuestas desde código HTTP
  factory ApiResponse.fromHttpError(int statusCode, {String? serverMessage}) {
    final friendlyMessage = ErrorMessages.fromStatusCode(statusCode);
    return ApiResponse.error(
      serverMessage ?? friendlyMessage,
      statusCode: statusCode,
      technicalError: 'HTTP $statusCode',
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, statusCode: $statusCode, data: $data, error: $error}';
  }
}
\n```\n
\n## Archivo: lib/services/auth/auth_repository.dart\n```
export 'auth_repository_web.dart'
    if (dart.library.io) 'auth_repository_io.dart';
\n```\n
\n## Archivo: lib/services/auth/auth_repository_io.dart\n```
import 'package:flutter/widgets.dart';

import '../../db/app_database.dart';
import '../../db/daos/user_dao.dart';
import '../../db/entities/user_entity.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../../models/user.dart';
import 'auth_service.dart';
import 'token_manager.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  final TokenManager _tokenManager;
  final AuthService _authService;
  late UserDao _userDao;

  AuthRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
    required TokenManager tokenManager,
    required AuthService authService,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager,
       _tokenManager = tokenManager,
       _authService = authService {
    _userDao = appDatabase.userDao;
  }

  // ========== MÉTODOS PRINCIPALES ==========

  // ✅ OFFLINE: Verificar si hay sesión guardada
  Future<User?> getCachedUser() async {
    try {
      // 1. Verificar si hay sesión válida en la BD
      final hasValidSession = await _userDao.hasValidSession();
      if (!hasValidSession) return null;

      // 2. Obtener el usuario de la sesión
      final session = await _userDao.getSession();
      if (session == null) return null;

      // 3. Obtener información del usuario desde la BD
      final userEntity = await _userDao.getUserById(session.userId);
      if (userEntity == null) return null;

      return _userDao.toUserModel(userEntity);
    } catch (e) {
      return null;
    }
  }

  // ✅ OFFLINE: Verificar si el token es válido localmente
  Future<bool> isTokenValidLocally() async {
    try {
      // 1. Verificar si hay token en el manager
      final token = await _tokenManager.getToken();
      if (token == null) return false;

      // 2. Verificar si hay sesión en la BD
      final hasValidSession = await _userDao.hasValidSession();
      if (!hasValidSession) return false;

      // 3. Verificar expiración del token JWT (simplificado)
      final session = await _userDao.getSession();
      return session != null && session.isValid;
    } catch (e) {
      return false;
    }
  }

  // ❌ SOLO ONLINE: Login real (necesita conexión)
  Future<ApiResponse<User>> loginOnline(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      // Verificar conexión
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para iniciar sesión');
      }

      // Usar el AuthService existente para el login online
      final response = await _authService.login(usernameOrEmail, password);

      if (!response.hasError && response.data != null) {
        // Guardar sesión localmente
        await _saveSessionLocally(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Guardar sesión localmente
  Future<void> _saveSessionLocally(User user) async {
    try {
      // 1. Guardar usuario en la BD
      final userEntity = UserEntity.fromUserModel(user);
      await _userDao.insertOrUpdateUser(userEntity);

      // 2. Obtener token del manager
      final token = await _tokenManager.getToken();
      final refreshToken = await _tokenManager.getRefreshToken();

      if (token != null) {
        // 3. Calcular expiración (asumir 24 horas por defecto)
        final expiresAt = DateTime.now().add(Duration(hours: 24));

        // 4. Guardar sesión en la BD
        final session = SessionEntity(
          userId: user.id,
          token: token,
          refreshToken: refreshToken ?? token,
          expiresAt: expiresAt,
          loggedInAt: DateTime.now(),
        );

        await _userDao.saveSession(session);
      }
    } catch (e) {
      debugPrint('Error guardando sesión localmente: $e');
    }
  }

  // ❌ SOLO ONLINE: Logout
  Future<ApiResponse<bool>> logoutOnline() async {
    try {
      // 1. Verificar conexión (opcional, pero buena práctica)
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        // Aún así podemos limpiar la sesión local
        await _clearLocalSession();
        return ApiResponse.success(true);
      }

      // 2. Usar el AuthService para logout en backend
      final response = await _authService.logout();

      // 3. Limpiar sesión local independientemente del resultado
      await _clearLocalSession();

      return response;
    } catch (e) {
      // En caso de error, igual limpiar sesión local
      await _clearLocalSession();
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Limpiar sesión local
  Future<void> _clearLocalSession() async {
    try {
      // 1. Limpiar tokens
      await _tokenManager.deleteToken();
      _apiClient.updateToken(null);

      // 2. Limpiar sesión de la BD
      await _userDao.clearSession();

      // NOTA: No eliminamos los usuarios de la BD
      // para mantener el cache de usuarios
    } catch (e) {
      debugPrint('Error limpiando sesión local: $e');
    }
  }

  // ✅ OFFLINE: Obtener usuario actual (desde cache)
  Future<User?> getCurrentUserOffline() async {
    return await getCachedUser();
  }

  // 🔄 Obtener usuario actual (intenta online, fallback a offline)
  Future<ApiResponse<User>> getCurrentUser({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          // Intentar obtener del backend
          final response = await _authService.getCurrentUser();

          if (!response.hasError && response.data != null) {
            // Guardar en cache
            await _saveSessionLocally(response.data!);
            return response;
          }
        } catch (e) {
          debugPrint('Error obteniendo usuario desde API: $e');
        }
      }

      // Fallback a datos locales
      final cachedUser = await getCachedUser();
      if (cachedUser != null) {
        return ApiResponse.success(cachedUser);
      }

      return ApiResponse.error('No hay usuario autenticado');
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Verificar permisos básicos
  Future<bool> hasPermissionOffline(String permission) async {
    try {
      final user = await getCachedUser();
      if (user == null) return false;

      // Verificaciones simples basadas en roles
      switch (permission) {
        case 'admin':
          return user.isAdmin;
        case 'view_users':
          return user.isAdmin || user.isConsult;
        case 'edit_users':
          return user.isAdmin;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final hasSession = await _userDao.hasValidSession();
      final session = await _userDao.getSession();
      final user = await getCachedUser();

      return {
        'hasSession': hasSession,
        'userId': user?.id ?? 0,
        'username': user?.username ?? 'No autenticado',
        'isAdmin': user?.isAdmin ?? false,
        'sessionValid': session?.isValid ?? false,
        'expiresIn': session?.timeUntilExpiry.toString() ?? 'N/A',
      };
    } catch (e) {
      return {'hasSession': false, 'error': e.toString()};
    }
  }

  // Validar token con renovación automática
  Future<bool> validateTokenWithRefresh() async {
    try {
      // 1. Verificar localmente primero
      final isValidLocally = await isTokenValidLocally();
      if (!isValidLocally) return false;

      // 2. Si hay conexión, intentar validar con backend
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final response = await _authService.validateToken();
        if (response.hasError) {
          // Intentar refrescar token
          final refreshResponse = await _authService.refreshAccessToken();
          return !refreshResponse.hasError;
        }
        return true;
      }

      // 3. Sin conexión, confiar en validación local
      return isValidLocally;
    } catch (e) {
      return false;
    }
  }

  AuthRepository createAuthRepository({
    required dynamic apiClient,
    required dynamic appDatabase,
    required dynamic connectivityManager,
    required dynamic tokenManager,
    required dynamic authService,
  }) {
    return AuthRepository(
      apiClient: apiClient,
      appDatabase: appDatabase,
      connectivityManager: connectivityManager,
      tokenManager: tokenManager,
      authService: authService,
    );
  }
}
\n```\n
\n## Archivo: lib/services/auth/auth_repository_stub.dart\n```
// lib/services/auth/auth_repository_stub.dart
class AuthRepository {
  AuthRepository({
    dynamic apiClient,
    dynamic appDatabase,
    dynamic connectivityManager,
    dynamic tokenManager,
    dynamic authService,
  });
}
\n```\n
\n## Archivo: lib/services/auth/auth_repository_web.dart\n```
// lib/services/auth/auth_repository_web.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../utils/connectivity_manager.dart';
import 'auth_service.dart';
import 'token_manager.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  final TokenManager _tokenManager;
  final AuthService _authService;

  AuthRepository({
    required ApiClient apiClient,
    required ConnectivityManager connectivityManager,
    required TokenManager tokenManager,
    required AuthService authService,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager,
       _tokenManager = tokenManager,
       _authService = authService;

  // ========== SESIÓN (solo token + prefs en web) ==========

  Future<User?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user');
      if (raw == null) return null;
      return User.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isTokenValidLocally() async {
    final token = await _tokenManager.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<ApiResponse<User>> loginOnline(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para iniciar sesión');
      }
      final response = await _authService.login(usernameOrEmail, password);
      if (!response.hasError && response.data != null) {
        await _saveUserToPrefs(response.data!);
      }
      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> logoutOnline() async {
    try {
      final response = await _authService.logout();
      await _clearLocalSession();
      return response;
    } catch (e) {
      await _clearLocalSession();
      return ApiResponse.fromException(e);
    }
  }

  Future<void> _clearLocalSession() async {
    await _tokenManager.deleteToken();
    _apiClient.updateToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  Future<User?> getCurrentUserOffline() async => getCachedUser();

  Future<ApiResponse<User>> getCurrentUser({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final response = await _authService.getCurrentUser();
        if (!response.hasError && response.data != null) {
          await _saveUserToPrefs(response.data!);
          return response;
        }
      }
      final cached = await getCachedUser();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error('No hay usuario autenticado');
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<bool> hasPermissionOffline(String permission) async {
    final user = await getCachedUser();
    if (user == null) return false;
    switch (permission) {
      case 'admin':
        return user.isAdmin;
      case 'view_users':
        return user.isAdmin || user.isConsult;
      case 'edit_users':
        return user.isAdmin;
      default:
        return false;
    }
  }

  Future<Map<String, dynamic>> getSessionStats() async {
    final user = await getCachedUser();
    final token = await _tokenManager.getToken();
    return {
      'hasSession': token != null && token.isNotEmpty,
      'userId': user?.id ?? 0,
      'username': user?.username ?? 'No autenticado',
      'isAdmin': user?.isAdmin ?? false,
      'sessionValid': token != null && token.isNotEmpty,
      'expiresIn': 'N/A',
    };
  }

  Future<bool> validateTokenWithRefresh() async {
    final isValidLocally = await isTokenValidLocally();
    if (!isValidLocally) return false;
    final hasNetwork = await _connectivityManager.hasNetworkConnection();
    if (hasNetwork) {
      final response = await _authService.validateToken();
      if (response.hasError) {
        final refresh = await _authService.refreshAccessToken();
        return !refresh.hasError;
      }
      return true;
    }
    return isValidLocally;
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', json.encode(user.toJson()));
    } catch (e) {
      debugPrint('Error guardando usuario en prefs: $e');
    }
  }

  AuthRepository createAuthRepository({
    required dynamic apiClient,
    dynamic appDatabase,
    required dynamic connectivityManager,
    required dynamic tokenManager,
    required dynamic authService,
  }) {
    return AuthRepository(
      apiClient: apiClient,
      connectivityManager: connectivityManager,
      tokenManager: tokenManager,
      authService: authService,
    );
  }
}
\n```\n
\n## Archivo: lib/services/auth/auth_service.dart\n```
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/rol.dart';
import 'token_manager.dart';
import '../../utils/error_messages.dart'; // <-- AÑADIR ESTA IMPORTACIÓN

class AuthService {
  final ApiClient _client;
  final TokenManager _tokenManager;

  AuthService({required ApiClient client, required TokenManager tokenManager})
    : _client = client,
      _tokenManager = tokenManager;

  Future<ApiResponse<Map<String, dynamic>>> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();

      if (refreshToken == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      // USAR EL NUEVO MÉTODO POST CON ApiResponse
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {'token': refreshToken},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.unauthorized,
          technicalError: response.technicalError,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.unexpectedError);
      }

      final jsonResponse = response.data!;

      if (!jsonResponse.containsKey('token')) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      final newAccessToken = jsonResponse['token'];
      final newRefreshToken = jsonResponse['refreshToken'] ?? refreshToken;

      if (newAccessToken == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      // Guardar nuevos tokens
      await _tokenManager.saveToken(newAccessToken);
      await _tokenManager.saveRefreshToken(newRefreshToken);
      _client.updateToken(newAccessToken);

      return ApiResponse.success({
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      });
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final sanitizedInput = usernameOrEmail.trim();
      final sanitizedPassword = password.trim();

      final body = {
        'nombreUsuario': sanitizedInput,
        'password': sanitizedPassword,
      };

      // USAR EL NUEVO MÉTODO POST
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        body: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos de login
        if (response.statusCode == 401) {
          return ApiResponse.error(
            ErrorMessages.invalidCredentials,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Devolver el error ya traducido desde ApiClient
        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      final jsonResponse = response.data!;

      final token = jsonResponse['token'];

      if (token == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      // Guardar token
      await _tokenManager.saveToken(token);
      _client.updateToken(token);

      // Guardar refresh token si viene
      if (jsonResponse.containsKey('refreshToken')) {
        await _tokenManager.saveRefreshToken(jsonResponse['refreshToken']);
      }

      // ✅ OBTENER USUARIO
      User user;

      // Opción 1: Si el backend envía usuario en la respuesta
      if (jsonResponse.containsKey('usuario')) {
        user = User.fromJson(jsonResponse['usuario']);
      }
      // Opción 2: Crear desde token JWT
      else {
        user = _createUserFromToken(token, sanitizedInput);
      }

      // Guardar usuario en cache
      await _saveUserToPreferences(user);

      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      await _tokenManager.deleteToken();
      _client.updateToken(null);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
        ErrorMessages.operationFailed,
        technicalError: 'Error en logout: $e',
      );
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      // ✅ PRIMERO: Intentar obtener usuario del token JWT
      try {
        final userFromToken = _createUserFromToken(token, 'usuario');

        // Si el usuario es 'usuario_temp', es porque el token no tiene la info correcta
        if (userFromToken.username != 'usuario_temp' &&
            userFromToken.username != 'usuario') {
          return ApiResponse.success(userFromToken);
        }
      } catch (e) {
        '';
      }

      // ✅ SEGUNDO: Si el token no tiene info, buscar en otros lugares

      // Opción A: Verificar si hay información en SharedPreferences
      try {
        final user = await _getUserFromPreferences();
        if (user != null) {
          return ApiResponse.success(user);
        }
      } catch (e) {
        '';
      }

      // Opción B: Si el backend tiene endpoint para usuario actual

      // Lista de posibles endpoints
      final possibleEndpoints = [
        '/auth/me',
        '/auth/profile',
        '/usuario/actual',
        '/usuario/perfil',
        '/user/me',
      ];

      for (final endpoint in possibleEndpoints) {
        try {
          final response = await _client.get<Map<String, dynamic>>(
            endpoint,
            fromJson: (json) => json as Map<String, dynamic>,
          );

          if (response.hasError) {
            continue; // Intentar con el siguiente endpoint
          }

          if (response.data != null) {
            final jsonResponse = response.data!;

            final user = User.fromJson(jsonResponse);

            // Guardar en cache para futuras consultas
            await _saveUserToPreferences(user);

            return ApiResponse.success(user);
          }
        } catch (e) {
          '';
        }
      }

      // ✅ ÚLTIMA OPCIÓN: Usuario mínimo desde información disponible

      final minimalUser = User(
        id: 1,
        username: 'Usuario',
        email: 'usuario@ejemplo.com',
        password: '',
        roles: [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );

      return ApiResponse.success(minimalUser);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Método para guardar/obtener usuario de SharedPreferences
  Future<void> _saveUserToPreferences(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', json.encode(user.toJson()));
    } catch (e) {
      '';
    }
  }

  Future<User?> _getUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user');

      if (userJson != null) {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      }
    } catch (e) {
      '';
    }
    return null;
  }

  Future<ApiResponse<bool>> validateToken() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
        ErrorMessages.operationFailed,
        technicalError: 'Error validando token: $e',
      );
    }
  }

  // Helper function
  int min(int a, int b) => a < b ? a : b;

  User _createUserFromToken(String token, String fallbackUsername) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Token JWT inválido');
      }

      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));

      return User(
        id: payload['id'] ?? 0,
        username:
            payload['nombreUsuario'] ?? payload['username'] ?? fallbackUsername,
        email: payload['email'] ?? '$fallbackUsername@temp.com',
        password: '',
        roles:
            (payload['roles'] as List<dynamic>?)?.map((role) {
              if (role is String) {
                final roleName = role.toLowerCase();
                return Rol(id: roleName == 'admin' ? 1 : 2, nombre: roleName);
              }
              return Rol(id: 2, nombre: 'consult');
            }).toList() ??
            [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return User(
        id: 1,
        username: fallbackUsername,
        email: '$fallbackUsername@temp.com',
        password: '',
        roles: [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );
    }
  }
}
\n```\n
\n## Archivo: lib/services/auth/token_expiry_manager.dart\n```
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/auth_provider.dart';
import '../../screen/auth/login_screen.dart';
import '../secure_token_manager.dart';
import '../service_locator.dart';

class TokenExpiryManager {
  final SecureTokenManager _tokenManager = ServiceLocator().secureTokenManager;
  Timer? _expiryTimer;
  Timer? _warningTimer;
  BuildContext? _currentContext;
  bool _isShowingExpiredDialog = false;

  // Configuración
  static const Duration _warningThreshold = Duration(minutes: 5);
  static const Duration _checkInterval = Duration(minutes: 1);

  void startMonitoring(BuildContext context) {
    // Guardar contexto para uso posterior
    _currentContext = context;

    if (_expiryTimer != null) return;
    _isShowingExpiredDialog = false;

    // Verificar periódicamente
    _expiryTimer = Timer.periodic(_checkInterval, (_) {
      _checkTokenExpiry();
    });

    // Verificar inmediatamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenExpiry();
    });
  }

  void stopMonitoring() {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();
    _expiryTimer = null;
    _warningTimer = null;
    _currentContext = null;
  }

  Future<void> _checkTokenExpiry() async {
    final context = _navigationContext;
    if (context == null) return;

    final token = await _tokenManager.getToken();
    if (token == null) return;

    final expiryInfo = _getTokenExpiryInfo(token);
    if (expiryInfo['isExpired'] == true) {
      if (context.mounted) {
        _handleTokenExpired(context);
      }
    } else if (expiryInfo['timeUntilExpiry'] <= _warningThreshold) {
      if (context.mounted) {
        _showExpiryWarning(context, expiryInfo['timeUntilExpiry']!);
      }
    }
  }

  // Resto del código permanece igual...
  Map<String, dynamic> _getTokenExpiryInfo(String token) {
    try {
      final parts = token.split('.');
      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
      final exp = payload['exp'] as int;
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiryTime.difference(now);

      return {
        'isExpired': timeUntilExpiry.isNegative,
        'timeUntilExpiry': timeUntilExpiry,
        'expiryTime': expiryTime,
        'minutesLeft': timeUntilExpiry.inMinutes,
      };
    } catch (e) {
      return {'isExpired': true, 'timeUntilExpiry': Duration.zero};
    }
  }

  BuildContext? get _navigationContext {
    return appNavigatorKey.currentContext ?? _currentContext;
  }

  void _handleTokenExpired(BuildContext context) {
    if (_isShowingExpiredDialog) return;
    _isShowingExpiredDialog = true;
    stopMonitoring();

    // Mostrar diálogo informativo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sesión Expirada'),
        content: Text(
          'Tu sesión ha expirado por seguridad. Por favor, inicia sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigationContext = _navigationContext;
              Navigator.of(dialogContext).pop();
              if (navigationContext != null) {
                _logoutAndRedirect(navigationContext);
              }
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showExpiryWarning(BuildContext context, Duration timeLeft) {
    final minutes = timeLeft.inMinutes;
    final seconds = timeLeft.inSeconds % 60;

    // Mostrar snackbar de advertencia (solo una vez)
    if (_warningTimer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tu sesión expirará en $minutes:${seconds.toString().padLeft(2, '0')} minutos',
          ),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Extender',
            onPressed: () => _tryRefreshToken(context),
          ),
        ),
      );

      // Programar próximo aviso
      _warningTimer = Timer(Duration(minutes: 1), () {
        _warningTimer = null;
      });
    }
  }

  Future<void> _tryRefreshToken(BuildContext context) async {
    final authService = ServiceLocator().authService;
    final result = await authService.refreshAccessToken();

    if (result.hasError) {
      if (context.mounted) {
        _logoutAndRedirect(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesión extendida exitosamente')),
        );
      }
    }
  }

  void _logoutAndRedirect(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();

    // Navegar al login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
\n```\n
\n## Archivo: lib/services/auth/token_manager.dart\n```
abstract class TokenManager {
  // Métodos existentes
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> hasToken();

  // 🔄 Añade estos métodos para refresh token
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<bool> hasRefreshToken();
}
\n```\n
\n## Archivo: lib/services/auth_security_service.dart\n```
import 'package:shared_preferences/shared_preferences.dart';

class AuthSecurityService {
  static const String _attemptsKey = 'login_attempts';
  static const String _lastAttemptKey = 'last_login_attempt';
  static const String _lockoutUntilKey = 'lockout_until';
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  Future<bool> canAttemptLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    final lockoutUntil = prefs.getString(_lockoutUntilKey);

    // Si está en periodo de bloqueo
    if (lockoutUntil != null) {
      final lockoutTime = DateTime.parse(lockoutUntil);
      final now = DateTime.now();

      if (now.isBefore(lockoutTime)) {
        return false; // Still locked out
      } else {
        // Reset attempts after lockout period
        await prefs.setInt(_attemptsKey, 0);
        await prefs.remove(_lockoutUntilKey);
      }
    }

    return attempts < _maxAttempts;
  }

  Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;

    await prefs.setInt(_attemptsKey, attempts);
    await prefs.setString(_lastAttemptKey, DateTime.now().toIso8601String());

    // Si excede los intentos máximos, activar bloqueo
    if (attempts >= _maxAttempts) {
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await prefs.setString(_lockoutUntilKey, lockoutUntil.toIso8601String());
    }
  }

  Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, 0);
    await prefs.remove(_lastAttemptKey);
    await prefs.remove(_lockoutUntilKey);
  }

  Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    return _maxAttempts - attempts;
  }

  Future<DateTime?> getLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getString(_lockoutUntilKey);
    return lockoutUntil != null ? DateTime.parse(lockoutUntil) : null;
  }

  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_attemptsKey) ?? 0;
  }

  Future<bool> isLockedOut() async {
    final lockoutTime = await getLockoutTime();
    if (lockoutTime == null) return false;

    return DateTime.now().isBefore(lockoutTime);
  }
}
\n```\n
\n## Archivo: lib/services/cache_service.dart\n```
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
\n```\n
\n## Archivo: lib/services/call_service.dart\n```
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CallService {
  static const MethodChannel _channel = MethodChannel('direct_call_channel');

  static Future<void> directCall(String number) async {
    try {
      final result = await _channel.invokeMethod("directCall", {
        "number": number,
      });

      // Verificar qué nos devuelve Android
      if (result == "permission_requested") {
        debugPrint("Se solicitó permiso en Android");
      } else if (result == "ok") {
        debugPrint("Llamada iniciada exitosamente");
      }
    } catch (e) {
      debugPrint("Error al hacer llamada directa: $e");
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/department_repository.dart\n```
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/department_dao.dart';
import '../../db/entities/department_entity.dart';
import '../../models/department_lite.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/department.dart';

class DepartmentRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  late DepartmentDao _departmentDao;

  DepartmentRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager {
    _departmentDao = appDatabase.departmentDao;
  }

  // Obtener todos los departamentos (OFFLINE-FIRST)
  Future<ApiResponse<List<Department>>> getDepartments({
    bool forceRefresh = false,
  }) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _getDepartmentsFromApi();

          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      return await _getDepartmentsFromLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener departamento por ID
  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    try {
      final localDepartment = await _departmentDao.getDepartmentById(id);

      if (localDepartment != null) {
        final department = _departmentDao.toDepartmentModel(localDepartment);
        return ApiResponse.success(department);
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getDepartmentByIdFromApi(id);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveDepartmentToLocal(apiResponse.data!);
        }

        return apiResponse;
      }

      return ApiResponse.error(
        'Departamento no encontrado localmente y sin conexión',
      );
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Crear departamento
  Future<ApiResponse<Department>> createDepartment(
    Department department,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para crear departamento');
      }

      final apiResponse = await _createDepartmentInApi(department);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveDepartmentToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar departamento
  Future<ApiResponse<Department>> updateDepartment(
    Department department,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para actualizar');
      }

      final apiResponse = await _updateDepartmentInApi(department);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveDepartmentToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Eliminar departamento
  Future<ApiResponse<bool>> deleteDepartment(int id) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para eliminar');
      }

      final apiResponse = await _deleteDepartmentFromApi(id);

      if (!apiResponse.hasError && apiResponse.data == true) {
        await _departmentDao.deleteDepartment(id);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar departamentos
  Future<ApiResponse<List<Department>>> searchDepartments(String query) async {
    try {
      final localResults = await _departmentDao.searchDepartments(query);
      final localDepartments = _departmentDao.toDepartmentModelList(
        localResults,
      );

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        final apiResponse = await _searchDepartmentsInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveDepartmentsToLocal(apiResponse.data!);

          // Combinar resultados
          final combinedDepartments = _mergeDepartmentLists(
            localDepartments,
            apiResponse.data!,
          );
          return ApiResponse.success(combinedDepartments);
        }
      }

      return ApiResponse.success(localDepartments);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Sincronizar departamentos
  // En el método syncDepartments, agrega prints:
  Future<bool> syncDepartments() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return false;
      }

      final apiResponse = await _getDepartmentsFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveDepartmentsToLocal(apiResponse.data!);

      // Verificar que se guardaron
      // final countAfter = await _departmentDao.countDepartments();

      return true;
    } catch (e) {
      return false;
    }
  }

  // También agrega logs en _getDepartmentsFromApi:
  Future<ApiResponse<List<Department>>> _getDepartmentsFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.departments,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener departamentos',
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamentos');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _getDepartmentByIdFromApi(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.departments}/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Departamento no encontrado');
      }

      try {
        final department = Department.fromJson(response.data!);
        return ApiResponse.success(department);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _createDepartmentInApi(
    Department department,
  ) async {
    try {
      final dto = department.toCreateDto();

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.departments,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final newDepartment = Department.fromJson(response.data!);
        return ApiResponse.success(newDepartment);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento creado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _updateDepartmentInApi(
    Department department,
  ) async {
    try {
      final dto = department.toUpdateDto();

      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiEndpoints.departments}/${department.id}',
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final updatedDepartment = Department.fromJson(response.data!);
        return ApiResponse.success(updatedDepartment);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento actualizado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> _deleteDepartmentFromApi(int id) async {
    try {
      final response = await _apiClient.delete<bool>(
        '${ApiEndpoints.departments}/$id',
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar departamento',
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Department>>> _searchDepartmentsInApi(
    String query,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.departments}/search/$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al buscar departamentos',
        );
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
      } catch (e) {
        return ApiResponse.error('Error al procesar búsqueda');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Métodos para base de datos local
  Future<ApiResponse<List<Department>>> _getDepartmentsFromLocal() async {
    try {
      final departments = await _departmentDao.getAllDepartmentsAsModels();
      return ApiResponse.success(departments);
    } catch (e) {
      return ApiResponse.error('Error al obtener departamentos locales');
    }
  }

  Future<void> _saveDepartmentsToLocal(List<Department> departments) async {
    try {
      final entities = departments
          .map((department) => DepartmentEntity.fromDepartmentModel(department))
          .toList();
      await _departmentDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar departamentos en local: $e');
    }
  }

  Future<void> _saveDepartmentToLocal(Department department) async {
    try {
      final entity = DepartmentEntity.fromDepartmentModel(department);
      await _departmentDao.insertOrUpdate(entity);
    } catch (e) {
      debugPrint('Error al guardar departamento en local: $e');
    }
  }

  // Helper para combinar listas
  List<Department> _mergeDepartmentLists(
    List<Department> list1,
    List<Department> list2,
  ) {
    final Map<int, Department> mergedMap = {};

    for (final department in list1) {
      mergedMap[department.id] = department;
    }

    for (final department in list2) {
      mergedMap[department.id] = department;
    }

    return mergedMap.values.toList();
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getLocalStats() async {
    final totalDepartments = await _departmentDao.countDepartments();
    final lastSyncDate = await _departmentDao.getLastSyncDate();

    return {
      'totalDepartments': totalDepartments,
      'lastSyncDate': lastSyncDate,
      'lastSyncFormatted': lastSyncDate?.toIso8601String() ?? 'Nunca',
    };
  }

  // Agregar al final de la clase DepartmentRepository, antes del último }

  // NUEVO: Obtener departamentos locales paginados
  Future<List<Department>> getLocalDepartmentsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      final offset = page * pageSize;
      final entities = await _departmentDao.getDepartmentsPaginated(
        limit: pageSize,
        offset: offset,
        searchQuery: searchQuery,
      );

      return _departmentDao.toDepartmentModelList(entities);
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener DepartmentLite paginados
  Future<List<DepartmentLite>> getLocalDepartmentsLitePaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      return await _departmentDao.getDepartmentsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: searchQuery,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar departamentos paginados
  Future<List<Department>> searchDepartmentsPaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalDepartmentsPaginated(
          page: page,
          pageSize: pageSize,
        );
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        // Intentar búsqueda en API
        try {
          final apiResponse = await _searchDepartmentsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);

            // Filtrar y paginar localmente después de guardar
            return await getLocalDepartmentsPaginated(
              page: page,
              pageSize: pageSize,
              searchQuery: query,
            );
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Usar búsqueda local
      return await getLocalDepartmentsPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar DepartmentLite paginados
  Future<List<DepartmentLite>> searchDepartmentsLitePaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalDepartmentsLitePaginated(
          page: page,
          pageSize: pageSize,
        );
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _searchDepartmentsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Siempre usar búsqueda local para paginación
      return await _departmentDao.getDepartmentsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener count con filtro
  Future<int> countDepartmentsWithFilter(String? searchQuery) async {
    try {
      return await _departmentDao.countDepartmentsWithFilter(searchQuery);
    } catch (e) {
      return 0;
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/department_service.dart\n```
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/department.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class DepartmentService {
  final ApiClient _client;

  DepartmentService(this._client);

  Future<ApiResponse<List<Department>>> getDepartments() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.departments,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.departmentById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final department = Department.fromJson(response.data!);
        return ApiResponse.success(department);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> createDepartment(
    Department department,
  ) async {
    try {
      final dto = department.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.departments,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.toLowerCase().contains('name') ??
                false) {
              errorMessage = 'Ya existe un departamento con ese nombre.';
            } else if (response.technicalError?.toLowerCase().contains(
                  'phone',
                ) ??
                false) {
              errorMessage = 'Ya existe un departamento con ese teléfono.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final newDepartment = Department.fromJson(response.data!);

        return ApiResponse.success(newDepartment);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> updateDepartment(
    Department department,
  ) async {
    try {
      final dto = department.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.departmentById(department.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedDepartment = Department.fromJson(response.data!);

        return ApiResponse.success(updatedDepartment);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteDepartment(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.departmentById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Verificar si hay relaciones (trabajadores asignados)
        if (response.statusCode == 409 ||
            (response.technicalError?.contains('relación') ?? false) ||
            (response.technicalError?.contains('dependencia') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el departamento porque tiene trabajadores asignados. '
            'Reasigna los trabajadores primero.',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/efemeride_repository.dart\n```
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/efemeride_dao.dart';
import '../../db/entities/efemeride_entity.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/efemeride.dart';

class EfemerideRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  late EfemerideDao _efemerideDao;

  EfemerideRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager {
    _efemerideDao = appDatabase.efemerideDao;
  }

  // ============ MÉTODOS PRINCIPALES (OFFLINE-FIRST) ============

  // Obtener todas las efemérides
  Future<ApiResponse<List<Efemeride>>> getEfemerides({
    bool forceRefresh = false,
  }) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork && forceRefresh) {
        try {
          final apiResponse = await _getEfemeridesFromApi();

          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveEfemeridesToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      return await _getEfemeridesFromLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener efeméride por ID
  Future<ApiResponse<Efemeride>> getEfemerideById(int id) async {
    try {
      final localEfemeride = await _efemerideDao.getEfemerideById(id);

      if (localEfemeride != null) {
        final efemeride = _efemerideDao.toEfemerideModel(localEfemeride);
        return ApiResponse.success(efemeride);
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getEfemerideByIdFromApi(id);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemerideToLocal(apiResponse.data!);
        }

        return apiResponse;
      }

      return ApiResponse.error(
        'Efeméride no encontrada localmente y sin conexión',
      );
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Crear efeméride
  Future<ApiResponse<Efemeride>> createEfemeride(Efemeride efemeride) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para crear efeméride');
      }

      final apiResponse = await _createEfemerideInApi(efemeride);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveEfemerideToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar efeméride
  Future<ApiResponse<Efemeride>> updateEfemeride(Efemeride efemeride) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para actualizar');
      }

      final apiResponse = await _updateEfemerideInApi(efemeride);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveEfemerideToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Eliminar efeméride
  Future<ApiResponse<bool>> deleteEfemeride(int id) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para eliminar');
      }

      final apiResponse = await _deleteEfemerideFromApi(id);

      if (!apiResponse.hasError && apiResponse.data == true) {
        await _efemerideDao.deleteEfemeride(id);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ============ MÉTODOS ESPECIALIZADOS ============

  // Obtener efemérides por mes
  Future<ApiResponse<List<Efemeride>>> getEfemeridesByMonth(int month) async {
    try {
      // Primero buscar localmente
      final now = DateTime.now();
      final localEntities = await _efemerideDao.getEfemeridesByMonth(
        now.year,
        month,
      );
      final localEfemerides = _efemerideDao.toEfemerideModelList(localEntities);

      // Si hay conexión, intentar actualizar
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getEfemeridesByMonthFromApi(month);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          // Combinar resultados
          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener efemérides por fecha
  Future<ApiResponse<List<Efemeride>>> getEfemeridesByDate(
    DateTime date,
  ) async {
    try {
      final localEntities = await _efemerideDao.getEfemeridesByDate(date);
      final localEfemerides = _efemerideDao.toEfemerideModelList(localEntities);

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getEfemeridesByDateFromApi(date);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener efemérides de hoy
  Future<ApiResponse<List<Efemeride>>> getTodayEfemerides() async {
    try {
      final localEfemerides = await _efemerideDao.getTodayEfemerides();

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getTodayEfemeridesFromApi();

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener efemérides próximas
  Future<ApiResponse<List<Efemeride>>> getUpcomingEfemerides(int days) async {
    try {
      final localEntities = await _efemerideDao.getUpcomingEfemerides(days);
      final localEfemerides = _efemerideDao.toEfemerideModelList(localEntities);

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getUpcomingEfemeridesFromApi(days);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener efemérides por año
  Future<ApiResponse<List<Efemeride>>> getEfemeridesByYear(int year) async {
    try {
      final localEntities = await _efemerideDao.getEfemeridesByYear(year);
      final localEfemerides = _efemerideDao.toEfemerideModelList(localEntities);

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getEfemeridesByYearFromApi(year);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar efemérides
  Future<ApiResponse<List<Efemeride>>> searchEfemerides(String query) async {
    try {
      final localEntities = await _efemerideDao.searchEfemerides(query);
      final localEfemerides = _efemerideDao.toEfemerideModelList(localEntities);

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _searchEfemeridesInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveEfemeridesToLocal(apiResponse.data!);

          final combined = _mergeEfemerideLists(
            localEfemerides,
            apiResponse.data!,
          );
          return ApiResponse.success(combined);
        }
      }

      return ApiResponse.success(localEfemerides);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Sincronizar todas las efemérides
  Future<bool> syncEfemerides() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) return false;

      final apiResponse = await _getEfemeridesFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveEfemeridesToLocal(apiResponse.data!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ MÉTODOS PRIVADOS PARA API ============

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.efemerides,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener efemérides',
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.error('Error al procesar efemérides');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> _getEfemerideByIdFromApi(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener efeméride',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Efeméride no encontrada');
      }

      try {
        final efemeride = Efemeride.fromJson(response.data!);
        return ApiResponse.success(efemeride);
      } catch (e) {
        return ApiResponse.error('Error al procesar efeméride');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> _createEfemerideInApi(
    Efemeride efemeride,
  ) async {
    try {
      final dto = efemeride.toCreateDto();

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.efemerides,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al crear efeméride');
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final newEfemeride = Efemeride.fromJson(response.data!);
        return ApiResponse.success(newEfemeride);
      } catch (e) {
        return ApiResponse.error('Error al procesar efeméride creada');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> _updateEfemerideInApi(
    Efemeride efemeride,
  ) async {
    try {
      final dto = efemeride.toUpdateDto();

      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(efemeride.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar efeméride',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final updatedEfemeride = Efemeride.fromJson(response.data!);
        return ApiResponse.success(updatedEfemeride);
      } catch (e) {
        return ApiResponse.error('Error al procesar efeméride actualizada');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> _deleteEfemerideFromApi(int id) async {
    try {
      final response = await _apiClient.delete<bool>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar efeméride',
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesByMonthFromApi(
    int month,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/mes/$month',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesByDateFromApi(
    DateTime date,
  ) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/fecha/$formattedDate',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _getTodayEfemeridesFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/hoy',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _getUpcomingEfemeridesFromApi(
    int days,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/proximos/$days',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesByYearFromApi(
    int year,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/año/$year',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> _searchEfemeridesInApi(
    String query,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}?search=$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  // ============ MÉTODOS PARA BASE DE DATOS LOCAL ============

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesFromLocal() async {
    try {
      final efemerides = await _efemerideDao.getAllEfemeridesAsModels();
      return ApiResponse.success(efemerides);
    } catch (e) {
      return ApiResponse.error('Error al obtener efemérides locales');
    }
  }

  Future<void> _saveEfemeridesToLocal(List<Efemeride> efemerides) async {
    try {
      final entities = efemerides
          .map((efemeride) => EfemerideEntity.fromEfemerideModel(efemeride))
          .toList();
      await _efemerideDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar efemérides en local: $e');
    }
  }

  Future<void> _saveEfemerideToLocal(Efemeride efemeride) async {
    try {
      final entity = EfemerideEntity.fromEfemerideModel(efemeride);
      await _efemerideDao.insertOrUpdate(entity);
    } catch (e) {
      debugPrint('Error al guardar efeméride en local: $e');
    }
  }

  // ============ HELPER METHODS ============

  // Combinar listas de efemérides
  List<Efemeride> _mergeEfemerideLists(
    List<Efemeride> list1,
    List<Efemeride> list2,
  ) {
    final Map<int, Efemeride> mergedMap = {};

    for (final efemeride in list1) {
      mergedMap[efemeride.id] = efemeride;
    }

    for (final efemeride in list2) {
      mergedMap[efemeride.id] = efemeride;
    }

    return mergedMap.values.toList();
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getLocalStats() async {
    try {
      final totalEfemerides = await _efemerideDao.countEfemerides();
      final lastSyncDate = await _efemerideDao.getLastSyncDate();
      final now = DateTime.now();
      final monthlyStats = await _efemerideDao.getMonthlyStats(now.year);

      return {
        'totalEfemerides': totalEfemerides,
        'lastSyncDate': lastSyncDate,
        'lastSyncFormatted': lastSyncDate?.toIso8601String() ?? 'Nunca',
        'currentYear': now.year,
        'monthlyStats': monthlyStats,
        'todayCount': (await _efemerideDao.getTodayEfemerides()).length,
      };
    } catch (e) {
      return {
        'totalEfemerides': 0,
        'lastSyncDate': null,
        'lastSyncFormatted': 'Nunca',
        'currentYear': DateTime.now().year,
        'monthlyStats': {},
        'todayCount': 0,
      };
    }
  }

  // ============ ESTADÍSTICAS ============

  // Obtener estadísticas (intenta online, fallback a offline)
  Future<Map<String, dynamic>> getEfemerideStats() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        // Intentar desde API
        final apiStats = await _fetchEfemerideStatsFromApi();
        if (apiStats.isNotEmpty) {
          return apiStats;
        }
      }

      // Fallback a estadísticas locales
      return await _getEfemerideStatsFromLocal();
    } catch (e) {
      return await _getEfemerideStatsFromLocal();
    }
  }

  // Obtener estadísticas desde API
  Future<Map<String, dynamic>> _fetchEfemerideStatsFromApi() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.efemerides}/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError || response.data == null) {
        return {};
      }

      return response.data!;
    } catch (e) {
      return {};
    }
  }

  // Obtener estadísticas locales
  Future<Map<String, dynamic>> _getEfemerideStatsFromLocal() async {
    try {
      final total = await _efemerideDao.countEfemerides();
      final now = DateTime.now();
      final monthlyStats = await _efemerideDao.getMonthlyStats(now.year);
      final todayCount = (await _efemerideDao.getTodayEfemerides()).length;
      final lastSync = await _efemerideDao.getLastSyncDate();

      final monthlyMap = <String, int>{};
      for (int i = 1; i <= 12; i++) {
        monthlyMap[i.toString()] = monthlyStats[i] ?? 0;
      }

      return {
        'total': total,
        'por_mes': monthlyMap,
        'por_tipo': {}, // Por defecto vacío
        'ultimo_mes': now.month,
        'hoy': todayCount,
        'last_sync': lastSync?.toIso8601String() ?? 'Nunca',
        'is_offline': true,
      };
    } catch (e) {
      return {
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
        'hoy': 0,
        'last_sync': 'Error',
        'is_offline': true,
      };
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/efemeride_service.dart\n```
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/efemeride.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class EfemerideService {
  final ApiClient _client;

  EfemerideService(this._client);

  // ========== BASIC CRUD METHODS ==========

  Future<ApiResponse<List<Efemeride>>> getEfemerides() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.efemerides,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();

        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> getEfemerideById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride no existe o ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final efemeride = Efemeride.fromJson(response.data!);
        return ApiResponse.success(efemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> createEfemeride(Efemeride efemeride) async {
    try {
      final dto = efemeride.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.efemerides,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('fecha') ?? false) {
              errorMessage = 'La fecha de la efeméride no es válida.';
            } else if (response.technicalError?.contains('dato') ?? false) {
              errorMessage = 'El dato de la efeméride es requerido.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final newEfemeride = Efemeride.fromJson(response.data!);

        return ApiResponse.success(newEfemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> updateEfemeride(Efemeride efemeride) async {
    try {
      final dto = efemeride.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(efemeride.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride no existe o ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedEfemeride = Efemeride.fromJson(response.data!);

        return ApiResponse.success(updatedEfemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteEfemeride(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride ya ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== FILTERED QUERIES ==========

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByMonth(int month) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/mes/$month',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para consultas filtradas, devolver lista vacía sin error
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByDate(
    DateTime date,
  ) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];

      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/fecha/$formattedDate',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> getTodayEfemerides() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/hoy',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> getUpcomingEfemerides(int days) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/proximos/$days',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByYear(int year) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/año/$year',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  // ========== SEARCH METHODS ==========

  Future<ApiResponse<List<Efemeride>>> searchEfemerides(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}?search=$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<Efemeride>>> searchEfemeridesByDato(
    String dato,
  ) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}?dato=$dato',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final efemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();
        return ApiResponse.success(efemerides);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  // ========== STATISTICS METHODS ==========

  Future<ApiResponse<Map<String, dynamic>>> getEfemerideStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.efemerides}/estadisticas',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Devolver estadísticas por defecto
        return ApiResponse.success({
          'total': 0,
          'por_mes': {},
          'por_tipo': {},
          'ultimo_mes': 0,
        });
      }

      if (response.data == null) {
        return ApiResponse.success({
          'total': 0,
          'por_mes': {},
          'por_tipo': {},
          'ultimo_mes': 0,
        });
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      return ApiResponse.success({
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
      });
    }
  }

  // ========== BULK OPERATIONS ==========

  Future<ApiResponse<List<Efemeride>>> createMultipleEfemerides(
    List<Efemeride> efemerides,
  ) async {
    try {
      final efemeridesJson = efemerides.map((e) => e.toJson()).toList();
      final response = await _client.post<List<dynamic>>(
        '${ApiEndpoints.efemerides}/multiple',
        body: {'efemerides': efemeridesJson},
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear múltiples efemérides',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final newEfemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();

        return ApiResponse.success(newEfemerides);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteMultipleEfemerides(List<int> ids) async {
    try {
      final response = await _client.post<bool>(
        '${ApiEndpoints.efemerides}/delete-multiple',
        body: {'ids': ids},
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar múltiples efemérides',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Método simplificado para estadísticas mensuales
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyEfemerideStats(
    int year,
  ) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.efemerides}/estadisticas/mensual/$year',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Devolver estadísticas vacías por mes
        final emptyStats = <String, dynamic>{};
        for (int i = 1; i <= 12; i++) {
          emptyStats[i.toString()] = 0;
        }
        return ApiResponse.success(emptyStats);
      }

      if (response.data == null) {
        final emptyStats = <String, dynamic>{};
        for (int i = 1; i <= 12; i++) {
          emptyStats[i.toString()] = 0;
        }
        return ApiResponse.success(emptyStats);
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      final emptyStats = <String, dynamic>{};
      for (int i = 1; i <= 12; i++) {
        emptyStats[i.toString()] = 0;
      }
      return ApiResponse.success(emptyStats);
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/local_repository.dart\n```
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/local_dao.dart';
import '../../db/entities/local_entity.dart';
import '../../models/local_lite.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/local.dart';

class LocalRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  late LocalDao _localDao;

  LocalRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager {
    _localDao = appDatabase.localDao;
  }

  // Obtener todos los locales (OFFLINE-FIRST)
  Future<ApiResponse<List<Local>>> getLocals({
    bool forceRefresh = false,
  }) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _getLocalsFromApi();

          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveLocalsToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      return await _getLocalsFromLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener local por ID
  Future<ApiResponse<Local>> getLocalById(int id) async {
    try {
      final localLocal = await _localDao.getLocalById(id);

      if (localLocal != null) {
        final local = _localDao.toLocalModel(localLocal);
        return ApiResponse.success(local);
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getLocalByIdFromApi(id);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveLocalToLocal(apiResponse.data!);
        }

        return apiResponse;
      }

      return ApiResponse.error('Local no encontrado localmente y sin conexión');
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Crear local
  Future<ApiResponse<Local>> createLocal(Local local) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para crear local');
      }

      final apiResponse = await _createLocalInApi(local);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveLocalToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar local
  Future<ApiResponse<Local>> updateLocal(Local local) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para actualizar');
      }

      final apiResponse = await _updateLocalInApi(local);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveLocalToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Eliminar local
  Future<ApiResponse<bool>> deleteLocal(int id) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para eliminar');
      }

      final apiResponse = await _deleteLocalFromApi(id);

      if (!apiResponse.hasError && apiResponse.data == true) {
        await _localDao.deleteLocal(id);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar locales
  Future<ApiResponse<List<Local>>> searchLocals(String query) async {
    try {
      final localResults = await _localDao.searchLocals(query);
      final localLocals = _localDao.toLocalModelList(localResults);

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        final apiResponse = await _searchLocalsInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveLocalsToLocal(apiResponse.data!);

          // Combinar resultados
          final combinedLocals = _mergeLocalLists(
            localLocals,
            apiResponse.data!,
          );
          return ApiResponse.success(combinedLocals);
        }
      }

      return ApiResponse.success(localLocals);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Sincronizar locales
  Future<bool> syncLocals() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) return false;

      final apiResponse = await _getLocalsFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveLocalsToLocal(apiResponse.data!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ MÉTODOS PRIVADOS ============

  // Métodos para API
  Future<ApiResponse<List<Local>>> _getLocalsFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.local, // Asegúrate de tener este endpoint
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al obtener locales');
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final locals = response.data!
            .map((json) => Local.fromJson(json))
            .toList();
        return ApiResponse.success(locals);
      } catch (e) {
        return ApiResponse.error('Error al procesar locales');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> _getLocalByIdFromApi(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.local}/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al obtener local');
      }

      if (response.data == null) {
        return ApiResponse.error('Local no encontrado');
      }

      try {
        final local = Local.fromJson(response.data!);
        return ApiResponse.success(local);
      } catch (e) {
        return ApiResponse.error('Error al procesar local');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> _createLocalInApi(Local local) async {
    try {
      final dto = local.toCreateDto();

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.local,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al crear local');
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final newLocal = Local.fromJson(response.data!);
        return ApiResponse.success(newLocal);
      } catch (e) {
        return ApiResponse.error('Error al procesar local creado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> _updateLocalInApi(Local local) async {
    try {
      final dto = local.toUpdateDto();

      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiEndpoints.local}/${local.id}',
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al actualizar local');
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final updatedLocal = Local.fromJson(response.data!);
        return ApiResponse.success(updatedLocal);
      } catch (e) {
        return ApiResponse.error('Error al procesar local actualizado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> _deleteLocalFromApi(int id) async {
    try {
      final response = await _apiClient.delete<bool>(
        '${ApiEndpoints.local}/$id',
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al eliminar local');
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Local>>> _searchLocalsInApi(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.local}/search/$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(response.error ?? 'Error al buscar locales');
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final locals = response.data!
            .map((json) => Local.fromJson(json))
            .toList();
        return ApiResponse.success(locals);
      } catch (e) {
        return ApiResponse.error('Error al procesar búsqueda');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Métodos para base de datos local
  Future<ApiResponse<List<Local>>> _getLocalsFromLocal() async {
    try {
      final locals = await _localDao.getAllLocalsAsModels();
      return ApiResponse.success(locals);
    } catch (e) {
      return ApiResponse.error('Error al obtener locales locales');
    }
  }

  Future<void> _saveLocalsToLocal(List<Local> locals) async {
    try {
      final entities = locals
          .map((local) => LocalEntity.fromLocalModel(local))
          .toList();
      await _localDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar locales en local: $e');
    }
  }

  Future<void> _saveLocalToLocal(Local local) async {
    try {
      final entity = LocalEntity.fromLocalModel(local);
      await _localDao.insertOrUpdate(entity);
    } catch (e) {
      debugPrint('Error al guardar local en local: $e');
    }
  }

  // Helper para combinar listas
  List<Local> _mergeLocalLists(List<Local> list1, List<Local> list2) {
    final Map<int, Local> mergedMap = {};

    for (final local in list1) {
      mergedMap[local.id] = local;
    }

    for (final local in list2) {
      mergedMap[local.id] = local;
    }

    return mergedMap.values.toList();
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getLocalStats() async {
    final totalLocals = await _localDao.countLocals();
    final lastSyncDate = await _localDao.getLastSyncDate();

    return {
      'totalLocals': totalLocals,
      'lastSyncDate': lastSyncDate,
      'lastSyncFormatted': lastSyncDate?.toIso8601String() ?? 'Nunca',
    };
  }

  // Agregar al final de la clase LocalRepository, antes del último }

  // NUEVO: Obtener locales locales paginados
  Future<List<Local>> getLocalLocalsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      final offset = page * pageSize;
      final entities = await _localDao.getLocalsPaginated(
        limit: pageSize,
        offset: offset,
        searchQuery: searchQuery,
      );

      return _localDao.toLocalModelList(entities);
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener LocalLite paginados
  Future<List<LocalLite>> getLocalLocalsLitePaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      return await _localDao.getLocalsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: searchQuery,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar locales paginados
  Future<List<Local>> searchLocalsPaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalLocalsPaginated(page: page, pageSize: pageSize);
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        // Intentar búsqueda en API
        try {
          final apiResponse = await _searchLocalsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveLocalsToLocal(apiResponse.data!);

            // Filtrar y paginar localmente después de guardar
            return await getLocalLocalsPaginated(
              page: page,
              pageSize: pageSize,
              searchQuery: query,
            );
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Usar búsqueda local
      return await getLocalLocalsPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar LocalLite paginados
  Future<List<LocalLite>> searchLocalsLitePaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalLocalsLitePaginated(
          page: page,
          pageSize: pageSize,
        );
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _searchLocalsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveLocalsToLocal(apiResponse.data!);
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Siempre usar búsqueda local para paginación
      return await _localDao.getLocalsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener count con filtro
  Future<int> countLocalsWithFilter(String? searchQuery) async {
    try {
      return await _localDao.countLocalsWithFilter(searchQuery);
    } catch (e) {
      return 0;
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/local_service.dart\n```
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/local.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class LocalService {
  final ApiClient _client;

  LocalService(this._client);

  Future<ApiResponse<List<Local>>> getLocal() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.local,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final local = response.data!
            .map((json) => Local.fromJson(json))
            .toList();
        return ApiResponse.success(local);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> getLocalById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.localById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final local = Local.fromJson(response.data!);
        return ApiResponse.success(local);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> createLocal(Local local) async {
    try {
      final dto = local.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.local,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación específicos
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.toLowerCase().contains('name') ??
                false) {
              errorMessage = 'Ya existe un local con ese nombre.';
            } else if (response.technicalError?.toLowerCase().contains(
                  'phone',
                ) ??
                false) {
              errorMessage = 'Ya existe un local con ese teléfono.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final newLocal = Local.fromJson(response.data!);

        return ApiResponse.success(newLocal);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Local>> updateLocal(Local local) async {
    try {
      final dto = local.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.localById(local.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedLocal = Local.fromJson(response.data!);

        return ApiResponse.success(updatedLocal);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteLocal(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.localById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Verificar si hay relaciones (trabajadores asignados)
        if (response.statusCode == 409 ||
            (response.technicalError?.contains('relación') ?? false) ||
            (response.technicalError?.contains('dependencia') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el local porque tiene trabajadores asignados. '
            'Reasigna los trabajadores primero.',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/user_repository.dart\n```
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/user_dao.dart';
import '../../db/entities/user_entity.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/create_usuario_dto.dart';
import 'user_service.dart';

class UserRepository {
  final ConnectivityManager _connectivityManager;
  final UserService _userService;
  late UserDao _userDao;

  UserRepository({
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
    required UserService userService,
  }) : _connectivityManager = connectivityManager,
       _userService = userService {
    _userDao = appDatabase.userDao;
  }

  // ========== MÉTODOS DE LECTURA (OFFLINE) ==========

  // ✅ OFFLINE: Obtener usuarios desde cache local
  Future<ApiResponse<List<User>>> getUsersLocal() async {
    try {
      final entities = await _userDao.getAllUsers();
      final users = _userDao.toUserModelList(entities);
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Error al obtener usuarios locales');
    }
  }

  // ✅ OFFLINE: Obtener usuario por ID desde cache
  Future<ApiResponse<User?>> getUserByIdLocal(int id) async {
    try {
      final entity = await _userDao.getUserById(id);
      if (entity == null) {
        return ApiResponse.success(null);
      }
      final user = _userDao.toUserModel(entity);
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.error('Error al obtener usuario local');
    }
  }

  // ✅ OFFLINE: Buscar usuarios localmente
  Future<ApiResponse<List<User>>> searchUsersLocal(String query) async {
    try {
      final entities = await _userDao.searchUsers(query);
      final users = _userDao.toUserModelList(entities);
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Error al buscar usuarios localmente');
    }
  }

  // ========== MÉTODOS CON SINCRONIZACIÓN ==========

  // 🔄 Obtener usuarios (offline-first con sincronización)
  Future<ApiResponse<List<User>>> getUsers({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      // Si hay red y se fuerza refresco, obtener de API
      if (hasNetwork && forceRefresh) {
        try {
          final apiResponse = await _getUsersFromApi();
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveUsersToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      // Fallback a datos locales
      return await getUsersLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // 🔄 Buscar usuarios (intenta online, fallback a offline)
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      // Primero buscar localmente
      final localResponse = await searchUsersLocal(query);
      final localUsers = localResponse.data ?? [];

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _searchUsersInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            // Guardar nuevos usuarios encontrados
            await _saveUsersToLocal(apiResponse.data!);

            // Combinar resultados
            final combined = _mergeUserLists(localUsers, apiResponse.data!);
            return ApiResponse.success(combined);
          }
        } catch (e) {
          debugPrint('⚠️ API de búsqueda falló: $e');
        }
      }

      return ApiResponse.success(localUsers);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== MÉTODOS DE ESCRITURA (SOLO ONLINE) ==========

  // ❌ SOLO ONLINE: Crear usuario
  Future<ApiResponse<User>> createUserOnline(
    CreateUsuarioDto usuarioDto,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para crear usuarios');
      }

      final response = await _userService.createUser(usuarioDto);

      if (!response.hasError && response.data != null) {
        // Guardar el nuevo usuario localmente
        await _saveUserToLocal(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ❌ SOLO ONLINE: Actualizar usuario
  Future<ApiResponse<User>> updateUserOnline(User user) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error(
          'Se requiere conexión para actualizar usuarios',
        );
      }

      final response = await _userService.updateUser(user);

      if (!response.hasError && response.data != null) {
        // Actualizar usuario localmente
        await _saveUserToLocal(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ❌ SOLO ONLINE: Eliminar usuario
  // Future<ApiResponse<bool>> deleteUserOnline(int id) async {
  //   try {
  //     final hasNetwork = await _connectivityManager.hasNetworkConnection();
  //     if (!hasNetwork) {
  //       return ApiResponse.error('Se requiere conexión para eliminar usuarios');
  //     }

  //     final response = await _userService.deleteUser(id);

  //     if (!response.hasError && response.data == true) {
  //       // Eliminar usuario localmente
  //       await _userDao.deleteUser(id);
  //     }

  //     return response;
  //   } catch (e) {
  //     return ApiResponse.fromException(e);
  //   }
  // }

  // ❌ SOLO ONLINE: Actualizar roles
  Future<ApiResponse<User>> updateUserRolesOnline(
    int userId,
    List<int> roleIds,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para actualizar roles');
      }

      return await _userService.updateUserRoles(userId, roleIds);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== SINCRONIZACIÓN ==========

  // 🔄 Sincronizar usuarios con el backend
  Future<bool> syncUsers() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) return false;

      final apiResponse = await _getUsersFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveUsersToLocal(apiResponse.data!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  Future<ApiResponse<List<User>>> _getUsersFromApi() async {
    try {
      final response = await _userService.getUsers();
      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<User>>> _searchUsersInApi(String query) async {
    try {
      final response = await _userService.searchUsers(query);
      return response;
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<void> _saveUsersToLocal(List<User> users) async {
    try {
      final entities = users
          .map((user) => UserEntity.fromUserModel(user))
          .toList();
      await _userDao.insertOrUpdateUsers(entities);
    } catch (e) {
      debugPrint('Error al guardar usuarios en local: $e');
    }
  }

  Future<void> _saveUserToLocal(User user) async {
    try {
      final entity = UserEntity.fromUserModel(user);
      await _userDao.insertOrUpdateUser(entity);
    } catch (e) {
      debugPrint('Error al guardar usuario en local: $e');
    }
  }

  List<User> _mergeUserLists(List<User> list1, List<User> list2) {
    final Map<int, User> mergedMap = {};
    for (final user in list1) {
      mergedMap[user.id] = user;
    }
    for (final user in list2) {
      mergedMap[user.id] = user;
    }
    return mergedMap.values.toList();
  }

  // ========== ESTADÍSTICAS ==========

  Future<Map<String, dynamic>> getLocalStats() async {
    try {
      final stats = await _userDao.getStats();
      return stats;
    } catch (e) {
      return {
        'totalUsers': 0,
        'lastSyncFormatted': 'Nunca',
        'hasSession': false,
      };
    }
  }

  // Obtener estadísticas (intenta online, fallback a offline)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        final response = await _userService.getUserStats();
        if (!response.hasError && response.data != null) {
          return response.data!;
        }
      }

      // Fallback a estadísticas locales
      final localStats = await getLocalStats();
      return {
        'total': localStats['totalUsers'] ?? 0,
        'admin': localStats['adminCount'] ?? 0,
        'consult':
            (localStats['totalUsers'] ?? 0) - (localStats['adminCount'] ?? 0),
        'activos': localStats['totalUsers'] ?? 0,
        'inactivos': 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      };
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/user_service.dart\n```
import '../../models/create_usuario_dto.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/rol.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class UserService {
  final ApiClient _client;

  UserService(this._client);

  // ========== USER METHODS ==========

  Future<ApiResponse<List<User>>> getUsers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.users,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> getUserById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.userById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final user = User.fromJson(response.data!);
        return ApiResponse.success(user);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> createUser(CreateUsuarioDto usuarioDto) async {
    try {
      final requestBody = usuarioDto.toJson();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('nombreUsuario') ?? false) {
              errorMessage = 'El nombre de usuario ya existe.';
            } else if (response.technicalError?.contains('email') ?? false) {
              errorMessage = 'El correo electrónico ya está registrado.';
            } else if (response.technicalError?.contains('password') ?? false) {
              errorMessage =
                  'La contraseña no cumple los requisitos. Debe tener al menos 6 caracteres.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 409) {
          return ApiResponse.error(
            'El usuario o email ya existen. Por favor, use datos diferentes.',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final user = User.fromJson(response.data!);

        return ApiResponse.success(user);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> updateUser(User user) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.userById(user.id),
        body: user.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteUser(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.userById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // No permitir eliminar el último administrador
        if (response.statusCode == 403 ||
            (response.technicalError?.contains('administrador') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el último administrador del sistema.',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> updateUserRoles(
    int userId,
    List<int> roleIds,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '${ApiEndpoints.userById(userId)}/roles',
        body: {'roleIds': roleIds},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> updateUserPassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '${ApiEndpoints.userById(userId)}/password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 400) {
          return ApiResponse.error(
            'La contraseña actual es incorrecta',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 422) {
          return ApiResponse.error(
            'La nueva contraseña no cumple los requisitos de seguridad',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== ROLE METHODS ==========

  Future<ApiResponse<List<Rol>>> getRoles() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.roles,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para roles, podemos devolver los predeterminados si hay error
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }

      if (response.data == null) {
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }

      try {
        final roles = response.data!.map((json) => Rol.fromJson(json)).toList();
        return ApiResponse.success(roles);
      } catch (e) {
        // Si hay error de parseo, devolver roles predeterminados
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }
    } catch (e) {
      return ApiResponse.success([
        Rol(id: 1, nombre: 'admin'),
        Rol(id: 2, nombre: 'consult'),
      ]);
    }
  }

  Future<ApiResponse<Rol>> getRoleById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.roleById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error('El rol no existe');
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final role = Rol.fromJson(response.data!);
        return ApiResponse.success(role);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== SEARCH & FILTER METHODS ==========

  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.users}?search=$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para búsqueda, devolver lista vacía sin error
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  // ========== STATISTICS METHODS ==========

  Future<ApiResponse<Map<String, dynamic>>> getUserStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.users}/estadisticas',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Para estadísticas, devolver valores por defecto
        return ApiResponse.success({
          'total': 0,
          'admin': 0,
          'consult': 0,
          'activos': 0,
          'inactivos': 0,
        });
      }

      if (response.data == null) {
        return ApiResponse.success({
          'total': 0,
          'admin': 0,
          'consult': 0,
          'activos': 0,
          'inactivos': 0,
        });
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      return ApiResponse.success({
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      });
    }
  }

  // Métodos restantes simplificados
  Future<ApiResponse<Rol>> createRole(Rol role) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.roles,
        body: role.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      return ApiResponse.success(Rol.fromJson(response.data!));
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Rol>> updateRole(Rol role) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.roleById(role.id),
        body: role.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      return ApiResponse.success(Rol.fromJson(response.data!));
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteRole(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.roleById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Rol>>> getUserRoles(int userId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.userById(userId)}/roles',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final roles = response.data!.map((json) => Rol.fromJson(json)).toList();
        return ApiResponse.success(roles);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<User>>> getUsersByRole(String roleName) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.users}?role=$roleName',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }
}
\n```\n
\n## Archivo: lib/services/data/worker_repository.dart\n```
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/worker_dao.dart';
import '../../db/entities/worker_entity.dart';
import '../../models/worker_lite.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/worker.dart';

class WorkerRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  late WorkerDao _workerDao;

  WorkerRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager {
    _workerDao = appDatabase.workerDao;
  }

  // ==================== MÉTODOS PRINCIPALES ====================

  // Obtener todos los trabajadores (OFFLINE-FIRST)
  // Future<ApiResponse<List<Worker>>> getWorkers({
  //   bool forceRefresh = false,
  // }) async {
  //   try {
  //     print('📱 WorkerRepository.getWorkers() - forceRefresh: $forceRefresh');

  //     // 1. Verificar si hay conexión de red (APN/WiFi)
  //     final hasNetwork = await _connectivityManager.hasNetworkConnection();
  //     print('📡 ¿Hay conexión de red (APN/WiFi)?: $hasNetwork');

  //     // 2. Verificar si hay datos locales
  //     final localCount = await _workerDao.countWorkers();
  //     print('💾 Datos locales: $localCount trabajadores');

  //     // 3. Si hay red, intentar cargar desde API
  //     if (hasNetwork) {
  //       print(
  //         '🔄 Intentando cargar desde API (asumiendo backend accesible)...',
  //       );

  //       try {
  //         final apiResponse = await _getWorkersFromApi();
  //         print(
  //           '📡 Respuesta API - Error: ${apiResponse.hasError}, Datos: ${apiResponse.data?.length ?? 0}',
  //         );

  //         if (!apiResponse.hasError && apiResponse.data != null) {
  //           // Guardar en base de datos local
  //           print(
  //             '💾 Guardando ${apiResponse.data!.length} trabajadores en local',
  //           );
  //           await _saveWorkersToLocal(apiResponse.data!);

  //           return apiResponse;
  //         } else {
  //           print('⚠️ API falló, usando datos locales si existen');
  //         }
  //       } catch (e) {
  //         print('🔥 Error en API call: $e');
  //       }
  //     }

  //     // 4. Fallback a datos locales
  //     print('💾 Cargando desde base de datos local');
  //     final localResponse = await _getWorkersFromLocal();

  //     if (localResponse.data != null && localResponse.data!.isNotEmpty) {
  //       print(
  //         '✅ ${localResponse.data!.length} trabajadores cargados desde cache',
  //       );
  //     } else {
  //       print('📭 Cache vacío');
  //     }

  //     return localResponse;
  //   } catch (e) {
  //     print('🔥 ERROR en WorkerRepository.getWorkers(): $e');
  //     return ApiResponse.fromException(e);
  //   }
  // }

  // Obtener trabajador por ID (OFFLINE-FIRST)
  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    try {
      // 1. Buscar primero en local
      final localWorker = await _workerDao.getWorkerById(id);

      if (localWorker != null) {
        final worker = _workerDao.toWorkerModel(localWorker);
        return ApiResponse.success(worker);
      }

      // 2. Si no está en local y hay conexión, buscar en API
      final hasConnection = await _connectivityManager.hasNetworkConnection();
      if (hasConnection) {
        final apiResponse = await _getWorkerByIdFromApi(id);

        if (!apiResponse.hasError && apiResponse.data != null) {
          // Guardar en local
          await _saveWorkerToLocal(apiResponse.data!);
        }

        return apiResponse;
      }

      // 3. Si no hay conexión y no está en local, error
      return ApiResponse.error(
        'Trabajador no encontrado localmente y sin conexión a internet',
        technicalError: 'No local data and no connection for worker ID: $id',
      );
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Crear trabajador (siempre intenta API primero)
  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    try {
      debugPrint('[WorkerRepository][CREATE] Start: ${_workerLog(worker)}');
      final hasConnection = await _connectivityManager.hasNetworkConnection();
      debugPrint('[WorkerRepository][CREATE] hasConnection=$hasConnection');

      if (!hasConnection) {
        debugPrint('[WorkerRepository][CREATE] No connection. Returning error');
        return ApiResponse.error(
          'No hay conexión a internet. No se puede crear el trabajador.',
          technicalError: 'No connection available for create operation',
        );
      }

      // Crear en API
      debugPrint('[WorkerRepository][CREATE] Sending to API');
      final apiResponse = await _createWorkerInApi(worker);
      debugPrint(
        '[WorkerRepository][CREATE] API response hasError=${apiResponse.hasError} status=${apiResponse.statusCode} error="${apiResponse.error}" technical="${apiResponse.technicalError}" data=${apiResponse.data != null ? _workerLog(apiResponse.data!) : null}',
      );

      if (!apiResponse.hasError && apiResponse.data != null) {
        // Guardar en local si se creó exitosamente
        debugPrint('[WorkerRepository][CREATE] Saving created worker to local DB');
        await _saveWorkerToLocal(apiResponse.data!);
        debugPrint('[WorkerRepository][CREATE] Local save completed');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('[WorkerRepository][CREATE] Exception: $e');
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar trabajador
  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    try {
      debugPrint('[WorkerRepository][EDIT] Start: ${_workerLog(worker)}');
      final hasConnection = await _connectivityManager.hasNetworkConnection();
      debugPrint('[WorkerRepository][EDIT] hasConnection=$hasConnection');

      if (!hasConnection) {
        debugPrint('[WorkerRepository][EDIT] No connection. Returning error');
        return ApiResponse.error(
          'No hay conexión a internet. Los cambios se guardarán localmente y se sincronizarán después.',
          technicalError: 'No connection for update, storing locally',
        );
      }

      // Actualizar en API
      debugPrint('[WorkerRepository][EDIT] Sending to API');
      final apiResponse = await _updateWorkerInApi(worker);
      debugPrint(
        '[WorkerRepository][EDIT] API response hasError=${apiResponse.hasError} status=${apiResponse.statusCode} error="${apiResponse.error}" technical="${apiResponse.technicalError}" data=${apiResponse.data != null ? _workerLog(apiResponse.data!) : null}',
      );

      if (!apiResponse.hasError && apiResponse.data != null) {
        // Actualizar en local
        debugPrint('[WorkerRepository][EDIT] Saving updated worker to local DB');
        await _saveWorkerToLocal(apiResponse.data!);
        debugPrint('[WorkerRepository][EDIT] Local save completed');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('[WorkerRepository][EDIT] Exception: $e');
      return ApiResponse.fromException(e);
    }
  }

  // Eliminar trabajador
  Future<ApiResponse<bool>> deleteWorker(int id) async {
    try {
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (!hasConnection) {
        return ApiResponse.error(
          'No hay conexión a internet. No se puede eliminar el trabajador.',
          technicalError: 'No connection for delete operation',
        );
      }

      // Eliminar de API
      final apiResponse = await _deleteWorkerFromApi(id);

      if (!apiResponse.hasError && apiResponse.data == true) {
        // Eliminar de local
        await _workerDao.deleteWorker(id);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar trabajadores (OFFLINE-FIRST)
  Future<ApiResponse<List<Worker>>> searchWorkers(String query) async {
    try {
      // 1. Buscar en local primero (siempre rápido)
      final localResults = await _workerDao.searchWorkers(query);
      final localWorkers = _workerDao.toWorkerModelList(localResults);

      // 2. Si hay conexión, buscar también en API para resultados actualizados
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (hasConnection) {
        final apiResponse = await _searchWorkersInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          // Combinar resultados (evitar duplicados)
          final apiWorkers = apiResponse.data!;
          final combinedWorkers = _mergeWorkerLists(localWorkers, apiWorkers);

          // Guardar nuevos resultados de API en local
          await _saveWorkersToLocal(apiWorkers);

          return ApiResponse.success(combinedWorkers);
        }
      }

      // 3. Retornar resultados locales
      return ApiResponse.success(localWorkers);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener cumpleaños (OFFLINE-FIRST)
  Future<ApiResponse<List<Worker>>> getBirthdayWorkers() async {
    try {
      // 1. Obtener todos los trabajadores locales
      final allLocalWorkers = await _workerDao.getAllWorkersAsModels();

      // 2. Filtrar los que tienen cumpleaños este mes
      final now = DateTime.now();
      final birthdayWorkers = allLocalWorkers
          .where(
            (worker) =>
                worker.birthdayDate != null &&
                worker.birthdayDate!.month == now.month,
          )
          .toList();

      // 3. Si hay conexión, obtener de API también
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (hasConnection) {
        final apiResponse = await _getBirthdayWorkersFromApi();

        if (!apiResponse.hasError && apiResponse.data != null) {
          // Combinar y actualizar local
          await _saveWorkersToLocal(apiResponse.data!);

          // Recalcular con datos actualizados
          final updatedLocalWorkers = await _workerDao.getAllWorkersAsModels();
          final updatedBirthdayWorkers = updatedLocalWorkers
              .where(
                (worker) =>
                    worker.birthdayDate != null &&
                    worker.birthdayDate!.month == now.month,
              )
              .toList();

          return ApiResponse.success(updatedBirthdayWorkers);
        }
      }

      return ApiResponse.success(birthdayWorkers);
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }

  // Obtener cumpleaños de hoy
  Future<ApiResponse<List<Worker>>> getTodayBirthdays() async {
    try {
      // 1. Obtener todos los trabajadores locales
      final allLocalWorkers = await _workerDao.getAllWorkersAsModels();

      // 2. Filtrar los que tienen cumpleaños hoy
      // final now = DateTime.now();
      final todayBirthdayWorkers = allLocalWorkers
          .where((worker) => worker.hasBirthdayToday)
          .toList();

      // 3. Si hay conexión, obtener de API también
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (hasConnection) {
        final apiResponse = await _getTodayBirthdaysFromApi();

        if (!apiResponse.hasError && apiResponse.data != null) {
          // Actualizar local
          await _saveWorkersToLocal(apiResponse.data!);

          // Recalcular
          final updatedLocalWorkers = await _workerDao.getAllWorkersAsModels();
          final updatedTodayBirthdayWorkers = updatedLocalWorkers
              .where((worker) => worker.hasBirthdayToday)
              .toList();

          return ApiResponse.success(updatedTodayBirthdayWorkers);
        }
      }

      return ApiResponse.success(todayBirthdayWorkers);
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }

  // ==================== MÉTODOS DE SINCRONIZACIÓN ====================

  // Sincronizar trabajadores con el backend
  Future<bool> syncWorkers() async {
    try {
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (!hasConnection) {
        return false;
      }

      // Obtener de API
      final apiResponse = await _getWorkersFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      // Guardar en local
      await _saveWorkersToLocal(apiResponse.data!);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener estadísticas de datos locales
  Future<Map<String, dynamic>> getLocalStats() async {
    final totalWorkers = await _workerDao.countWorkers();
    final lastSyncDate = await _workerDao.getLastSyncDate();

    return {
      'totalWorkers': totalWorkers,
      'lastSyncDate': lastSyncDate,
      'lastSyncFormatted': lastSyncDate?.toIso8601String() ?? 'Nunca',
    };
  }

  // ==================== MÉTODOS PRIVADOS ====================

  // Métodos para API (copiados/modificados de WorkerService)
  Future<ApiResponse<List<Worker>>> _getWorkersFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.workers,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener trabajadores',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar datos de trabajadores',
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> _getWorkerByIdFromApi(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Trabajador no encontrado');
      }

      try {
        final worker = Worker.fromJson(response.data!);
        return ApiResponse.success(worker);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar datos del trabajador',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> _createWorkerInApi(Worker worker) async {
    try {
      final dto = worker.toCreateDto();
      debugPrint('[WorkerRepository][CREATE][API] POST ${ApiEndpoints.workers}');
      debugPrint('[WorkerRepository][CREATE][API] Body: $dto');

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.workers,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        debugPrint(
          '[WorkerRepository][CREATE][API] Error status=${response.statusCode} error="${response.error}" technical="${response.technicalError}"',
        );
        return ApiResponse.error(
          response.error ?? 'Error al crear trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        debugPrint('[WorkerRepository][CREATE][API] Empty response data');
        return ApiResponse.error('Error al procesar respuesta del servidor');
      }

      try {
        debugPrint('[WorkerRepository][CREATE][API] Raw response: ${response.data}');
        final newWorker = Worker.fromJson(response.data!);
        debugPrint('[WorkerRepository][CREATE][API] Parsed worker: ${_workerLog(newWorker)}');
        return ApiResponse.success(newWorker);
      } catch (e) {
        debugPrint('[WorkerRepository][CREATE][API] Parse exception: $e');
        return ApiResponse.error(
          'Error al procesar trabajador creado',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      debugPrint('[WorkerRepository][CREATE][API] Exception: $e');
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> _updateWorkerInApi(Worker worker) async {
    try {
      final dto = worker.toUpdateDto();
      debugPrint(
        '[WorkerRepository][EDIT][API] PUT ${ApiEndpoints.workerById(worker.id)}',
      );
      debugPrint('[WorkerRepository][EDIT][API] Body: $dto');

      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.workerById(worker.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        debugPrint(
          '[WorkerRepository][EDIT][API] Error status=${response.statusCode} error="${response.error}" technical="${response.technicalError}"',
        );
        return ApiResponse.error(
          response.error ?? 'Error al actualizar trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        debugPrint('[WorkerRepository][EDIT][API] Empty response data');
        return ApiResponse.error('Error al procesar respuesta del servidor');
      }

      try {
        debugPrint('[WorkerRepository][EDIT][API] Raw response: ${response.data}');
        final updatedWorker = Worker.fromJson(response.data!);
        debugPrint(
          '[WorkerRepository][EDIT][API] Parsed worker: ${_workerLog(updatedWorker)}',
        );
        return ApiResponse.success(updatedWorker);
      } catch (e) {
        debugPrint('[WorkerRepository][EDIT][API] Parse exception: $e');
        return ApiResponse.error(
          'Error al procesar trabajador actualizado',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      debugPrint('[WorkerRepository][EDIT][API] Exception: $e');
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> _deleteWorkerFromApi(int id) async {
    try {
      final response = await _apiClient.delete<bool>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Worker>>> _searchWorkersInApi(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.workerSearch}$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al buscar trabajadores',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar búsqueda',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Worker>>> _getBirthdayWorkersFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]); // Silencioso
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.success([]); // Silencioso
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso
    }
  }

  Future<ApiResponse<List<Worker>>> _getTodayBirthdaysFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos/hoy',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]); // Silencioso
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.success([]); // Silencioso
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso
    }
  }

  // Métodos para base de datos local
  // Future<ApiResponse<List<Worker>>> _getWorkersFromLocal() async {
  //   try {
  //     final workers = await _workerDao.getAllWorkersAsModels();
  //     return ApiResponse.success(workers);
  //   } catch (e) {
  //     return ApiResponse.error(
  //       'Error al obtener trabajadores locales',
  //       technicalError: 'Local DB Error: $e',
  //     );
  //   }
  // }

  Future<void> _saveWorkersToLocal(List<Worker> workers) async {
    try {
      final entities = workers
          .map((worker) => WorkerEntity.fromWorkerModel(worker))
          .toList();
      await _workerDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar trabajadores en local: $e');
    }
  }

  Future<void> _saveWorkerToLocal(Worker worker) async {
    try {
      final entity = WorkerEntity.fromWorkerModel(worker);
      await _workerDao.insertOrUpdate(entity);
    } catch (e) {
      debugPrint('Error al guardar trabajador en local: $e');
    }
  }

  // Helper para determinar si debemos refrescar desde API
  // Future<bool> _shouldRefreshFromApi() async {
  //   try {
  //     final lastSyncDate = await _workerDao.getLastSyncDate();

  //     if (lastSyncDate == null) {
  //       return true;
  //     }

  //     final now = DateTime.now();
  //     final difference = now.difference(lastSyncDate);

  //     // Refrescar si pasaron más de 30 minutos desde la última sincronización
  //     return difference.inMinutes > 30;
  //   } catch (e) {
  //     // En caso de error, intentar refrescar
  //     return true;
  //   }
  // }

  // Helper para combinar listas de trabajadores (evitar duplicados)
  List<Worker> _mergeWorkerLists(List<Worker> list1, List<Worker> list2) {
    final Map<int, Worker> mergedMap = {};

    // Agregar todos de list1
    for (final worker in list1) {
      mergedMap[worker.id] = worker;
    }

    // Agregar/sobrescribir con list2 (API tiene prioridad)
    for (final worker in list2) {
      mergedMap[worker.id] = worker;
    }

    return mergedMap.values.toList();
  }

  // AGREGAR estos métodos a worker_repository.dart:

  // ==================== PAGINACIÓN ====================

  // Obtener trabajadores paginados (OFFLINE-FIRST)
  Future<ApiResponse<List<WorkerLite>>> getWorkersPaged({
    int page = 0,
    int limit = 20, // Tamaño de página más pequeño para mejor rendimiento
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Verificar si hay conexión de red
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      // 2. Si hay red y es primera página o refresh forzado, intentar API
      if (hasNetwork && (page == 0 || forceRefresh)) {
        try {
          final apiResponse = await _getWorkersPagedFromApi(page, limit);

          if (!apiResponse.hasError && apiResponse.data != null) {
            // Guardar en base de datos local si es página 0
            if (page == 0) {
              await _saveWorkersPagedToLocal(apiResponse.data!, page);
            }
            return apiResponse;
          } else if (page == 0) {}
        } catch (e) {
          debugPrint('🔥 Error en API call página $page: $e');
        }
      }

      // 3. Cargar desde base de datos local (paginado)
      final localResponse = await _getWorkersPagedFromLocal(page, limit);

      if (localResponse.data != null && localResponse.data!.isNotEmpty) {
      } else if (page == 0) {
        debugPrint('📭 Cache vacío para página $page');
      }

      return localResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar trabajadores paginados
  Future<ApiResponse<List<WorkerLite>>> searchWorkersPaged(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      // 1. Buscar en local primero (siempre rápido)
      final localResults = await _workerDao.searchWorkersLitePaged(
        query,
        page,
        limit,
      );

      // 2. Si hay conexión y es página 0, buscar también en API
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (hasConnection && page == 0) {
        final apiResponse = await _searchWorkersInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          // Guardar resultados de API en local
          await _saveWorkersToLocal(apiResponse.data!);

          // Obtener resultados actualizados de local
          final updatedResults = await _workerDao.searchWorkersLitePaged(
            query,
            page,
            limit,
          );
          return ApiResponse.success(updatedResults);
        }
      }

      return ApiResponse.success(localResults);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ==================== MÉTODOS PRIVADOS PAGINADOS ====================

  Future<ApiResponse<List<WorkerLite>>> _getWorkersPagedFromApi(
    int page,
    int limit,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.workers}?page=$page&limit=$limit',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener trabajadores',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => WorkerLite.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar datos de trabajadores',
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<WorkerLite>>> _getWorkersPagedFromLocal(
    int page,
    int limit,
  ) async {
    try {
      final workers = await _workerDao.getWorkersLitePaged(page, limit);
      return ApiResponse.success(workers);
    } catch (e) {
      return ApiResponse.error(
        'Error al obtener trabajadores locales',
        technicalError: 'Local DB Error: $e',
      );
    }
  }

  Future<void> _saveWorkersPagedToLocal(
    List<WorkerLite> workers,
    int page,
  ) async {
    try {
      // Convertir WorkerLite a Worker para guardar en BD
      final fullWorkers = workers.map((lite) => lite.toWorker()).toList();
      final entities = fullWorkers
          .map((worker) => WorkerEntity.fromWorkerModel(worker))
          .toList();

      // Si es página 0, limpiar cache antes de insertar
      if (page == 0) {
        await _workerDao.deleteAllWorkers();
      }

      await _workerDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar trabajadores paginados en local: $e');
    }
  }

  // Modificar el método getWorkers existente para usar paginación por defecto
  Future<ApiResponse<List<Worker>>> getWorkers({
    bool forceRefresh = false,
  }) async {
    // Por compatibilidad, llamar a la versión paginada con límite grande
    final response = await getWorkersPaged(
      page: 0,
      limit: 1000, // Límite grande para mantener compatibilidad
      forceRefresh: forceRefresh,
    );

    // Convertir WorkerLite a Worker
    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error',
        technicalError: response.technicalError,
      );
    }

    final workers = response.data!.map((lite) => lite.toWorker()).toList();
    return ApiResponse.success(workers);
  }

  String _workerLog(Worker worker) {
    return {
      'id': worker.id,
      'nombre': worker.name,
      'apellido': worker.lastName,
      'carnetIdentidad': worker.carnetID,
      'numeroCelular': worker.phone,
      'direccion': worker.address,
      'fechaCumpleanno': worker.fechaCumpleannos,
      'departamentoId': worker.departamentoID,
      'localId': worker.localId,
    }.toString();
  }
}
\n```\n
\n## Archivo: lib/services/data/worker_service.dart\n```
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/worker.dart';
import '../../utils/error_messages.dart';

class WorkerService {
  final ApiClient _client;

  WorkerService(this._client);

  Future<ApiResponse<List<Worker>>> getWorkers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.workers,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar específicamente 404
        if (response.statusCode == 404) {
          return ApiResponse.error(
            ErrorMessages.dataNotFound,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final worker = Worker.fromJson(response.data!);
        return ApiResponse.success(worker);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    try {
      final dto = worker.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.workers,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('carnet') ?? false) {
              errorMessage =
                  'El número de carnet ya existe. Por favor, use uno diferente.';
            } else if (response.technicalError?.contains('phone') ?? false) {
              errorMessage = 'El número de teléfono ya está registrado.';
            } else if (response.technicalError?.contains('email') ?? false) {
              errorMessage = 'El correo electrónico ya está registrado.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final newWorker = Worker.fromJson(response.data!);

        return ApiResponse.success(newWorker);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    try {
      final dto = worker.toUpdateDto();

      if (worker.id <= 0) {
        return ApiResponse.error(
          'ID de trabajador inválido para actualización',
          technicalError: 'Invalid worker ID: ${worker.id}',
        );
      }

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.workerById(worker.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El trabajador no existe o ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedWorker = Worker.fromJson(response.data!);

        return ApiResponse.success(updatedWorker);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteWorker(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        // Manejar específicamente 404
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El trabajador ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Worker>>> searchWorkers(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workerSearch}$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Worker>>> getBirthdayWorkers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Si falla, devolver lista vacía sin mostrar error al usuario
        // (esto es opcional, depende de tus requerimientos)
        return ApiResponse.success([]);
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.success([]); // Silencioso para cumpleaños
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }

  Future<ApiResponse<List<Worker>>> getTodayBirthdays() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos/hoy',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]); // Silencioso para cumpleaños
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
      } catch (e) {
        return ApiResponse.success([]); // Silencioso para cumpleaños
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }
}
\n```\n
\n## Archivo: lib/services/memory_cache_service.dart\n```
import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Tipos de caché disponibles
enum CacheType {
  volatile, // Datos que cambian frecuentemente (10 min)
  stable, // Datos estables (2 horas)
  critical, // Datos críticos que rara vez cambian (24 horas)
  permanent, // Sin expiración (hasta limpieza manual)
}

/// Servicio de caché en memoria con expiración automática y políticas avanzadas
class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();

  factory MemoryCacheService() => _instance;

  MemoryCacheService._internal() {
    // Iniciar limpieza periódica automática
    _startCleanupTimer();
  }

  // ========== CONFIGURACIÓN ==========
  static const Duration _defaultCleanupInterval = Duration(minutes: 1);
  static const int _maxCacheSize = 100; // Máximo de items en caché
  static const Duration _defaultVolatileTTL = Duration(minutes: 10);
  static const Duration _defaultStableTTL = Duration(hours: 2);
  static const Duration _defaultCriticalTTL = Duration(hours: 24);

  // ========== ESTRUCTURAS DE DATOS ==========
  final Map<String, CacheEntry> _cache = HashMap(); // HashMap para acceso O(1)
  final Map<String, List<String>> _categoryKeys = {};
  final LinkedHashMap<String, DateTime> _accessLog =
      LinkedHashMap(); // Para LRU

  Timer? _cleanupTimer;

  // ========== MÉTODOS PÚBLICOS ==========

  /// Obtiene un item del caché, actualizando su posición en LRU
  Future<T?> get<T>(String key) async {
    final entry = _cache[key];

    if (entry == null) return null;

    // Verificar expiración
    if (entry.expiresAt != null && entry.expiresAt!.isBefore(DateTime.now())) {
      await _removeEntry(key);
      return null;
    }

    // Actualizar tiempo de acceso (LRU)
    _accessLog[key] = DateTime.now();

    // Incrementar contador de accesos para estadísticas
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();

    return entry.data as T;
  }

  /// Almacena un item en caché con política configurable
  Future<void> set<T>(
    String key,
    T data, {
    CacheType type = CacheType.stable,
    String? category,
    Duration? customTTL,
    bool forceUpdate = false,
  }) async {
    // Si el caché está lleno, eliminar el menos usado recientemente (LRU)
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(key)) {
      await _evictLRUItem();
    }

    // Configurar TTL según tipo
    Duration ttl;
    switch (type) {
      case CacheType.volatile:
        ttl = _defaultVolatileTTL;
        break;
      case CacheType.stable:
        ttl = _defaultStableTTL;
        break;
      case CacheType.critical:
        ttl = _defaultCriticalTTL;
        break;
      case CacheType.permanent:
        ttl = Duration(days: 365 * 100); // ~100 años
        break;
    }

    final expiresAt = customTTL != null
        ? DateTime.now().add(customTTL)
        : DateTime.now().add(ttl);

    // Actualizar o crear entrada
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: expiresAt,
      category: category,
      type: type,
      created: DateTime.now(),
    );

    _accessLog[key] = DateTime.now();

    // Registrar en categoría si se especificó
    if (category != null) {
      _categoryKeys.putIfAbsent(category, () => []);
      if (!_categoryKeys[category]!.contains(key)) {
        _categoryKeys[category]!.add(key);
      }
    }
  }

  /// Obtiene o calcula y cachea si no existe (patrón cache-aside)
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetchData, {
    CacheType type = CacheType.stable,
    String? category,
    Duration? ttl,
  }) async {
    // Intentar obtener del caché
    final cached = await get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Obtener datos frescos
    final freshData = await fetchData();

    // Almacenar en caché
    await set<T>(
      key,
      freshData,
      type: type,
      category: category,
      customTTL: ttl,
    );

    return freshData;
  }

  /// Invalida una entrada específica
  Future<void> invalidate(String key) async {
    await _removeEntry(key);
  }

  /// Invalida todas las entradas de una categoría
  Future<void> invalidateCategory(String category) async {
    final keys = _categoryKeys[category]?.toList() ?? [];

    for (final key in keys) {
      await _removeEntry(key);
    }

    _categoryKeys.remove(category);
  }

  /// Invalida entradas por patrón (usando wildcards)
  Future<void> invalidatePattern(String pattern) async {
    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      if (_matchesPattern(key, pattern)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      await _removeEntry(key);
    }
  }

  /// Limpia todo el caché
  Future<void> clear() async {
    _cache.clear();
    _categoryKeys.clear();
    _accessLog.clear();
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int volatileCount = 0;
    int stableCount = 0;
    int criticalCount = 0;
    int permanentCount = 0;

    int totalAccessCount = 0;
    DateTime? oldestEntry;
    DateTime? newestEntry;

    for (final entry in _cache.values) {
      // Contar por tipo
      switch (entry.type) {
        case CacheType.volatile:
          volatileCount++;
          break;
        case CacheType.stable:
          stableCount++;
          break;
        case CacheType.critical:
          criticalCount++;
          break;
        case CacheType.permanent:
          permanentCount++;
          break;
      }

      // Contar expirados
      if (entry.expiresAt != null && entry.expiresAt!.isBefore(now)) {
        expiredCount++;
      }

      // Estadísticas de acceso
      totalAccessCount += entry.accessCount;

      // Encontrar entrada más antigua y más nueva
      if (oldestEntry == null || entry.created.isBefore(oldestEntry)) {
        oldestEntry = entry.created;
      }
      if (newestEntry == null || entry.created.isAfter(newestEntry)) {
        newestEntry = entry.created;
      }
    }

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredCount,
      'byType': {
        'volatile': volatileCount,
        'stable': stableCount,
        'critical': criticalCount,
        'permanent': permanentCount,
      },
      'categories': _categoryKeys.length,
      'accessStats': {
        'totalAccesses': totalAccessCount,
        'avgAccessPerEntry': _cache.isEmpty
            ? 0
            : totalAccessCount / _cache.length,
      },
      'age': {
        'oldest': oldestEntry?.toIso8601String(),
        'newest': newestEntry?.toIso8601String(),
      },
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// Precalienta el caché con datos comunes
  Future<void> prewarm(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await set(entry.key, entry.value, type: CacheType.stable);
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Inicia el timer de limpieza automática
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_defaultCleanupInterval, (_) {
      _cleanExpiredEntries();
    });
  }

  /// Limpia entradas expiradas
  Future<void> _cleanExpiredEntries() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.expiresAt != null &&
          entry.value.expiresAt!.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await _removeEntry(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint(
        '[MemoryCache] Limpiadas ${expiredKeys.length} entradas expiradas',
      );
    }
  }

  /// Elimina el item menos usado recientemente (LRU)
  Future<void> _evictLRUItem() async {
    if (_accessLog.isEmpty) return;

    // Encontrar la clave con el acceso más antiguo
    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _accessLog.entries) {
      if (oldestAccess == null || entry.value.isBefore(oldestAccess)) {
        oldestAccess = entry.value;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      await _removeEntry(lruKey);
    }
  }

  /// Elimina una entrada de todas las estructuras
  Future<void> _removeEntry(String key) async {
    final entry = _cache[key];

    if (entry != null && entry.category != null) {
      // Remover de la categoría
      final categoryList = _categoryKeys[entry.category!];
      categoryList?.remove(key);

      if (categoryList?.isEmpty ?? false) {
        _categoryKeys.remove(entry.category!);
      }
    }

    _cache.remove(key);
    _accessLog.remove(key);
  }

  /// Verifica si una clave coincide con un patrón (soporta * como wildcard)
  bool _matchesPattern(String key, String pattern) {
    if (pattern == '*') return true;

    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(key);
  }

  /// Estimación del uso de memoria (aproximada)
  int _estimateMemoryUsage() {
    // Estimación simple: ~100 bytes por entrada + tamaño de datos
    int estimatedBytes = _cache.length * 100;

    for (final entry in _cache.values) {
      if (entry.data is String) {
        estimatedBytes += (entry.data as String).length * 2; // UTF-16
      } else if (entry.data is List) {
        estimatedBytes += (entry.data as List).length * 8; // Aproximación
      } else if (entry.data is Map) {
        estimatedBytes += (entry.data as Map).length * 16;
      }
    }

    return estimatedBytes;
  }

  /// Dispose: detiene el timer de limpieza
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}

/// Entrada individual del caché
class CacheEntry {
  final dynamic data;
  final DateTime? expiresAt;
  final String? category;
  final CacheType type;
  final DateTime created;

  DateTime lastAccessed;
  int accessCount;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.category,
    required this.type,
    required this.created,
  }) : lastAccessed = created,
       accessCount = 0;
}
\n```\n
\n## Archivo: lib/services/notification_handler.dart\n```
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
\n```\n
\n## Archivo: lib/services/secure_token_manager.dart\n```
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth/token_manager.dart';

class SecureTokenManager implements TokenManager {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      throw Exception('No se pudo guardar el token de acceso');
    }
  }

  @override // ✅ Ahora es parte de la interfaz
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      throw Exception('No se pudo guardar el refresh token');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  @override // ✅ Ahora es parte de la interfaz
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      '';
    }
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  @override // ✅ Ahora es parte de la interfaz
  Future<bool> hasRefreshToken() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  // Método adicional para verificar la disponibilidad del almacenamiento seguro
  Future<bool> isSecureStorageAvailable() async {
    try {
      await _storage.write(key: 'test_key', value: 'test_value');
      await _storage.delete(key: 'test_key');
      return true;
    } catch (e) {
      return false;
    }
  }
}
\n```\n
\n## Archivo: lib/services/service_locator.dart\n```
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../utils/connectivity_manager.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_service.dart';
import 'auth/token_expiry_manager.dart';
import 'auth/token_manager.dart';
import 'auth_security_service.dart';
import 'data/department_repository.dart';
import 'data/efemeride_repository.dart';
import 'data/local_repository.dart';
import 'data/user_repository.dart';
import 'data/worker_repository.dart';
import 'data/worker_service.dart';
import 'data/department_service.dart';
import 'data/local_service.dart';
import 'data/user_service.dart';
import 'data/efemeride_service.dart';
import 'secure_token_manager.dart';

// Importar los providers
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'sync_service.dart';

// AGREGAR IMPORT DEL NUEVO SERVICIO DE ACTUALIZACIONES
import 'update/update_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late ApiClient _apiClient;
  late TokenManager _tokenManager;
  late SecureTokenManager _secureTokenManager;
  late AuthSecurityService _authSecurityService;
  late AuthService _authService;
  late WorkerService _workerService;
  late DepartmentService _departmentService;
  late LocalService _localService;
  late UserService _userService;
  late EfemerideService _efemerideService;

  // SERVICIOS EXISTENTES
  late AppDatabase _appDatabase;
  late ConnectivityManager _connectivityManager;
  late SyncService _syncService;

  late TokenExpiryManager _tokenExpiryManager;

  // AGREGAR NUEVO SERVICIO DE ACTUALIZACIONES
  late UpdateService _updateService;

  // Providers
  late AuthProvider _authProvider;
  late UserProvider _userProvider;

  // Repositorios
  late WorkerRepository _workerRepository;
  late DepartmentRepository _departmentRepository;
  late LocalRepository _localRepository;
  late EfemerideRepository _efemerideRepository;
  late AuthRepository _authRepository;
  late UserRepository _userRepository;

  Future<void> initialize() async {
    // ========== FASE 1: SERVICIOS BÁSICOS Y SEGURIDAD ==========
    _secureTokenManager = SecureTokenManager();
    _authSecurityService = AuthSecurityService();
    _tokenManager = _secureTokenManager;
    final token = await _secureTokenManager.getToken();
    _apiClient = ApiClient(baseUrl: ApiEndpoints.baseUrl, token: token);

    // ========== FASE 1.5: INICIALIZAR UPDATE SERVICE (necesita package_info) ==========
    // El UpdateService necesita inicializarse temprano para verificar al inicio
    _updateService = UpdateService();

    // ========== FASE 2: SERVICIOS DE NEGOCIO ==========
    _authService = AuthService(
      client: _apiClient,
      tokenManager: _secureTokenManager,
    );
    _workerService = WorkerService(_apiClient);
    _departmentService = DepartmentService(_apiClient);
    _localService = LocalService(_apiClient);
    _userService = UserService(_apiClient);
    _efemerideService = EfemerideService(_apiClient);

    // ========== FASE 3: SERVICIOS OFFLINE ==========
    if (!kIsWeb) {
      _appDatabase = await AppDatabase.instance();
      await _appDatabase.initializeDaos();
    }

    _connectivityManager = ConnectivityManager();

    _workerRepository = WorkerRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _departmentRepository = DepartmentRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _localRepository = LocalRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _efemerideRepository = EfemerideRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _authRepository = createAuthRepository(
      apiClient: _apiClient,
      appDatabase: kIsWeb ? null : _appDatabase,
      connectivityManager: _connectivityManager,
      tokenManager: _secureTokenManager,
      authService: _authService,
    );

    _userRepository = UserRepository(
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
      userService: _userService,
    );

    _syncService = SyncService(appDatabase: _appDatabase);

    _syncService.setServices(
      workerService: _workerService,
      departmentService: _departmentService,
      localService: _localService,
      userService: _userService,
      efemerideService: _efemerideService,
    );

    _syncService.setWorkerRepository(_workerRepository);
    _syncService.setDepartmentRepository(_departmentRepository);
    _syncService.setLocalRepository(_localRepository);
    _syncService.setEfemerideRepository(_efemerideRepository);
    _syncService.setAuthRepository(_authRepository);
    _syncService.setUserRepository(_userRepository);

    // ========== FASE 4: SERVICIOS ADICIONALES ==========
    _tokenExpiryManager = TokenExpiryManager();

    // ========== FASE 5: PROVIDERS ==========
    _authProvider = AuthProvider();
    _userProvider = UserProvider();
  }

  // Getters para servicios
  ApiClient get apiClient => _apiClient;
  TokenManager get tokenManager => _tokenManager;
  SecureTokenManager get secureTokenManager => _secureTokenManager;
  AuthSecurityService get authSecurityService => _authSecurityService;
  AuthService get authService => _authService;
  WorkerService get workerService => _workerService;
  DepartmentService get departmentService => _departmentService;
  LocalService get localService => _localService;
  UserService get userService => _userService;
  EfemerideService get efemerideService => _efemerideService;

  // GETTERS PARA SERVICIOS EXISTENTES
  AppDatabase get appDatabase => _appDatabase;
  ConnectivityManager get connectivityManager => _connectivityManager;
  SyncService get syncService => _syncService;
  WorkerRepository get workerRepository => _workerRepository;
  DepartmentRepository get departmentRepository => _departmentRepository;
  LocalRepository get localRepository => _localRepository;
  EfemerideRepository get efemerideRepository => _efemerideRepository;
  AuthRepository get authRepository => _authRepository;
  UserRepository get userRepository => _userRepository;
  TokenExpiryManager get tokenExpiryManager => _tokenExpiryManager;

  // NUEVO GETTER PARA UPDATE SERVICE
  UpdateService get updateService => _updateService;

  // Getters para providers
  AuthProvider get authProvider => _authProvider;
  UserProvider get userProvider => _userProvider;

  void dispose() {
    _apiClient.dispose();
    _appDatabase.close();
    // Agregar dispose del updateService
    _updateService.dispose();
  }
}
\n```\n
\n## Archivo: lib/services/sync_service.dart\n```
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import 'auth/auth_repository.dart';
import 'data/efemeride_repository.dart';
import 'data/local_repository.dart';
import 'data/user_repository.dart';
import 'data/worker_repository.dart';
import 'data/department_repository.dart'; // NUEVO
import 'data/worker_service.dart';
import 'data/department_service.dart';
import 'data/local_service.dart';
import 'data/user_service.dart';
import 'data/efemeride_service.dart';

class SyncService {
  final AppDatabase appDatabase;

  // Servicios para conectarse al backend

  // Repositories para offline
  late WorkerRepository _workerRepository;
  late DepartmentRepository _departmentRepository; // NUEVO
  late LocalRepository _localRepository;
  late EfemerideRepository _efemerideRepository;
  late AuthRepository _authRepository;
  late UserRepository _userRepository;

  SyncService({required this.appDatabase});

  // Configurar servicios después de inicializarlos
  void setServices({
    required WorkerService workerService,
    required DepartmentService departmentService,
    required LocalService localService,
    required UserService userService,
    required EfemerideService efemerideService,
  }) {}

  void setWorkerRepository(WorkerRepository repository) {
    _workerRepository = repository;
  }

  // NUEVO: Configurar department repository
  void setDepartmentRepository(DepartmentRepository repository) {
    _departmentRepository = repository;
  }

  void setLocalRepository(LocalRepository repository) {
    _localRepository = repository;
  }

  void setEfemerideRepository(EfemerideRepository repository) {
    _efemerideRepository = repository;
  }

  void setAuthRepository(AuthRepository repository) {
    _authRepository = repository;
  }

  void setUserRepository(UserRepository repository) {
    _userRepository = repository;
  }

  // Método para sincronizar todos los datos
  Future<bool> syncAllData() async {
    try {
      bool allSuccess = true;
      List<String> errors = [];

      // 1. Sincronizar trabajadores
      try {
        final workerSyncSuccess = await _workerRepository.syncWorkers();
        if (!workerSyncSuccess) {
          errors.add('Trabajadores');
          allSuccess = false;
        }
      } catch (e) {
        errors.add('Trabajadores');
        allSuccess = false;
      }

      // 2. Sincronizar departamentos
      try {
        final departmentSyncSuccess = await _departmentRepository
            .syncDepartments();
        if (!departmentSyncSuccess) {
          errors.add('Departamentos');
          allSuccess = false;
        }
      } catch (e) {
        errors.add('Departamentos');
        allSuccess = false;
      }

      try {
        final localSyncSuccess = await _localRepository.syncLocals();
        if (!localSyncSuccess) {
          errors.add('Locales');
          allSuccess = false;
        }
      } catch (e) {
        errors.add('Locales');
        allSuccess = false;
      }

      try {
        final efemerideSyncSuccess = await _efemerideRepository
            .syncEfemerides();
        if (!efemerideSyncSuccess) {
          errors.add('Efemérides');
          allSuccess = false;
        }
      } catch (e) {
        errors.add('Efemérides');
        allSuccess = false;
      }

      try {
        final userSyncSuccess = await _userRepository.syncUsers();
        if (!userSyncSuccess) {
          errors.add('Usuarios');
          allSuccess = false;
        }
      } catch (e) {
        errors.add('Usuarios');
        allSuccess = false;
      }

      if (errors.isNotEmpty) {
        debugPrint('⚠️ Sincronización parcial: Fallaron ${errors.join(', ')}');
      } else {
        debugPrint('🎉 Sincronización completada exitosamente');
      }

      return allSuccess;
    } catch (e) {
      return false;
    }
  }

  // Método para sincronizar solo datos nuevos/cambiados
  Future<bool> syncIncremental() async {
    try {
      // Aquí podrías implementar lógica más inteligente:
      // - Solo sincronizar datos modificados desde última sincronización
      // - Usar timestamps para comparar
      // - Sincronizar por lotes pequeños

      // Por ahora, simplemente llamamos a syncAllData
      return await syncAllData();
    } catch (e) {
      return false;
    }
  }

  // NUEVO: Sincronizar solo un tipo específico de datos
  Future<bool> syncSpecificData(String dataType) async {
    try {
      switch (dataType.toLowerCase()) {
        case 'trabajadores':
        case 'workers':
          return await _workerRepository.syncWorkers();

        case 'departamentos':
        case 'departments':
          return await _departmentRepository.syncDepartments();

        case 'locales':
        case 'local':
          return await _localRepository.syncLocals();

        case 'efemerides':
        case 'efemeride':
          return await _efemerideRepository.syncEfemerides();
        case 'usuarios':
        case 'users':
          return await _userRepository.syncUsers();

        case 'auth':
        case 'sesion':
          return await _authRepository.validateTokenWithRefresh();
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // NUEVO: Verificar estado de sincronización
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      // Obtener estadísticas de cada repository
      final workerStats = await _workerRepository.getLocalStats();

      final departmentStats = await _departmentRepository.getLocalStats();

      final efemerideStats = await _efemerideRepository.getLocalStats();

      final localStats = await _localRepository.getLocalStats();
      final userStats = await _userRepository.getLocalStats();
      final authStats = await _authRepository.getSessionStats();

      return {
        'workers': {
          'count': workerStats['totalWorkers'],
          'lastSync': workerStats['lastSyncFormatted'],
        },
        'departments': {
          'count': departmentStats['totalDepartments'],
          'lastSync': departmentStats['lastSyncFormatted'],
        },
        'locals': {
          'count': localStats['totalLocals'],
          'lastSync': localStats['lastSyncFormatted'],
        },
        'efemerides': {
          // NUEVO
          'count': efemerideStats['totalEfemerides'],
          'lastSync': efemerideStats['lastSyncFormatted'],
          'today': efemerideStats['todayCount'],
        },
        'users': {
          // NUEVO
          'count': userStats['totalUsers'],
          'lastSync': userStats['lastSyncFormatted'],
        },
        'auth': {
          // NUEVO
          'hasSession': authStats['hasSession'],
          'username': authStats['username'],
          'isAdmin': authStats['isAdmin'],
        },
        'lastFullSync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': 'No se pudo obtener el estado'};
    }
  }
}
\n```\n
\n## Archivo: lib/services/update/update_repository.dart\n```
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
\n```\n
\n## Archivo: lib/services/update/update_service.dart\n```
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/update_info.dart';
import '../../utils/notification_utils.dart';
import 'update_repository.dart';

class UpdateService {
  final UpdateRepository _repository;
  PackageInfo? _packageInfo;
  BuildContext? _currentContext;

  UpdateService() : _repository = UpdateRepository();

  UpdateRepository get repository => _repository;

  Future<void> _initializePackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
  }

  // ==================== VERIFICACIÓN ====================

  Future<UpdateInfo?> checkUpdates({
    bool forceCheck = false,
    bool showNotification = true,
  }) async {
    try {
      await _initializePackageInfo();

      if (!forceCheck) {
        final shouldCheck = await _repository.shouldCheckForUpdates();
        if (!shouldCheck) {
          return null;
        }
      }

      final updateInfo = await _repository.checkForUpdates();
      if (updateInfo == null) {
        return null;
      }

      await _repository.saveLastCheckTime();

      // final currentVersion = _packageInfo?.version ?? '1.0.0';
      final currentVersionCode =
          int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;

      if (updateInfo.versionCode > currentVersionCode) {
        final ignoredVersion = await _repository.getIgnoredUpdate();
        if (ignoredVersion != updateInfo.latestVersion) {
          return updateInfo;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================== MÉTODO PRINCIPAL ====================
  Future<void> downloadUpdate(
    UpdateInfo updateInfo,
    BuildContext context,
  ) async {
    _currentContext = context;

    try {
      // 1. Permisos
      await _requestAndroidPermissions(context);

      // 2. Mostrar progreso inicial
      _showProgressDialog(0.0, updateInfo.latestVersion);

      // 3. Descargar
      final apkFile = await _downloadApkToDownloads(
        updateInfo.apkUrl,
        updateInfo.latestVersion,
      );

      if (apkFile == null) throw Exception('Descarga falló');

      // 4. Cerrar diálogo de progreso
      _closeProgressDialog();

      // 5. Mostrar mensaje de descarga completa CON RETRASO
      await Future.delayed(const Duration(milliseconds: 300));
      _showDownloadCompleteDialog(apkFile.path, updateInfo.latestVersion);
    } catch (e) {
      _closeProgressDialog();
      await Future.delayed(const Duration(milliseconds: 300));
      _showErrorDialog('Error al descargar: ${e.toString()}');
    } finally {
      _currentContext = null;
    }
  }

  // ==================== DESCARGA ====================

  Future<File?> _downloadApkToDownloads(String url, String version) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      // Directorio de descargas del sistema
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        final created = await downloadsDir.create(recursive: true);
        if (!(await created.exists())) {
          throw Exception('No se pudo crear Downloads');
        }
      }

      // Nombre del archivo seguro
      final fileName = 'Phonebook_v${version.replaceAll('.', '_')}.apk';
      final apkFile = File('${downloadsDir.path}/$fileName');

      // Eliminar si ya existe
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      // Guardar archivo
      await apkFile.writeAsBytes(response.bodyBytes);

      return apkFile;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== UI Y DIÁLOGOS ====================

  void _showProgressDialog(double progress, String version) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    final percentage = (progress * 100).toStringAsFixed(0);

    showDialog(
      context: _currentContext!,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono animado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: progress < 1.0
                      ? Icon(
                          Icons.download,
                          key: const ValueKey('downloading'),
                          size: 48,
                          color: Colors.blue[700],
                        )
                      : Icon(
                          Icons.check_circle,
                          key: const ValueKey('completed'),
                          size: 48,
                          color: Colors.green,
                        ),
                ),
                const SizedBox(height: 20),

                // Título
                Flexible(
                  child: Text(
                    progress < 1.0 ? 'Descargando...' : '¡Descarga Completa!',
                    softWrap: true,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Versión
                Text(
                  'Versión $version',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Barra de progreso
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Fondo
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Progreso
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width:
                            MediaQuery.of(_currentContext!).size.width *
                            0.6 *
                            progress,
                        decoration: BoxDecoration(
                          color: progress < 1.0
                              ? Colors.blue[600]
                              : Colors.green,
                          borderRadius: BorderRadius.circular(6),
                          gradient: progress < 1.0
                              ? LinearGradient(
                                  colors: [
                                    Colors.blue[600]!,
                                    Colors.blue[400]!,
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Porcentaje
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress < 1.0 ? Colors.blue[700] : Colors.green,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje
                Text(
                  progress < 1.0
                      ? 'Por favor, no cierre la aplicación'
                      : 'La descarga se completó exitosamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadCompleteDialog(String apkPath, String version) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    final fileName = apkPath.split('/').last;
    final fileSize = File(apkPath).lengthSync() ~/ (1024 * 1024); // MB

    showDialog(
      context: _currentContext!,
      barrierDismissible: true, // Cambiado a true para que se pueda cerrar
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_done, color: Colors.green),
            SizedBox(width: 10),
            Flexible(
              child: Text('✅ Descarga Completa', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La versión $version se descargó correctamente.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Información del archivo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• Nombre: $fileName'),
                    Text('• Tamaño: $fileSize MB'),
                    Text('• Ubicación: Carpeta Descargas'),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes instalarlo manualmente cuando desees.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botón para cancelar/cerrar
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar este diálogo
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _closeProgressDialog() {
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.of(_currentContext!, rootNavigator: true).pop();
    }
  }

  void _showErrorDialog(String message) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    showDialog(
      context: _currentContext!,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== PERMISOS ====================

  Future<void> _requestAndroidPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final permissions = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (!permissions[Permission.storage]!.isGranted) {
      throw Exception('Permiso de almacenamiento necesario');
    }
  }

  // ==================== MÉTODOS PÚBLICOS ====================

  Future<void> downloadUpdateDirectly(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    await downloadUpdate(updateInfo, context);
  }

  Future<void> showUpdateNotification(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    final shouldShow = await _repository.shouldShowUpdateNotification(
      updateInfo,
    );
    if (!shouldShow) return;

    if (updateInfo.mandatory && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Actualización Obligatoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versión ${updateInfo.latestVersion}'),
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(updateInfo.releaseNotes),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => downloadUpdate(updateInfo, context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('DESCARGAR AHORA'),
            ),
          ],
        ),
      );
    } else {
      await _repository.saveIgnoredUpdate(updateInfo.latestVersion);
      await NotificationUtils.showUpdateNotification(
        title: '📱 Actualización Disponible',
        body: 'Nueva versión ${updateInfo.latestVersion} disponible',
        version: updateInfo.latestVersion,
        hasAction: true,
      );
    }
  }

  Future<void> checkAndNotifyIfNeeded(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    try {
      final updateInfo = await checkUpdates(forceCheck: forceCheck);
      if (updateInfo != null && context.mounted) {
        await showUpdateNotification(context, updateInfo);
      }
    } catch (e) {
      debugPrint('Error en checkAndNotifyIfNeeded: $e');
    }
  }

  Future<String> getCurrentVersion() async {
    await _initializePackageInfo();
    return _packageInfo?.version ?? '1.0.0';
  }

  Future<int> getCurrentVersionCode() async {
    await _initializePackageInfo();
    return int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;
  }

  static Future<void> savePendingNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_update_notification', payload);
  }

  static Future<String?> getPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_update_notification');
  }

  static Future<void> clearPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_update_notification');
  }

  void dispose() {
    _repository.dispose();
  }
}
\n```\n
\n## Archivo: lib/utils/connectivity_manager.dart\n```
// VERSIÓN SIMPLIFICADA - SOLO PARA APN
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  final Connectivity _connectivity = Connectivity();

  // Solo verificar si hay conexión de red (APN/WiFi)
  Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Si existe al menos un tipo de conexión distinto de none, hay red
      final hasConnection = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );

      return hasConnection;
    } catch (e) {
      return false;
    }
  }

  // Escuchar cambios en la conectividad
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  // Verificar tipo específico de conexión
  Future<List<ConnectivityResult>> getConnectionType() async {
    return await _connectivity.checkConnectivity();
  }
}
\n```\n
\n## Archivo: lib/utils/debouncer.dart\n```
import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}
\n```\n
\n## Archivo: lib/utils/dialog_error_handler.dart\n```
import 'package:flutter/material.dart';

class DialogErrorHandler {
  static String getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network') ||
        error.contains('host lookup')) {
      return '❌ No hay conexión a internet. Verifique su conexión.';
    }

    if (error.contains('timeout')) {
      return '⏰ El servidor está tardando en responder. Intente más tarde.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return '⚠️ El registro ya existe. Verifique los datos.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return '📝 Complete todos los campos requeridos.';
    }

    if (error.contains('invalid') || error.contains('inválido')) {
      return '⚠️ Datos inválidos. Verifique la información.';
    }

    if (error.contains('500') || error.contains('server error')) {
      return '🔧 Error en el servidor. Nuestro equipo ha sido notificado.';
    }

    if (error.contains('401') || error.contains('unauthorized')) {
      return '🔐 Su sesión ha expirado. Por favor, inicie sesión nuevamente.';
    }

    if (error.contains('404') || error.contains('not found')) {
      return '🔍 El recurso no existe o ha sido eliminado.';
    }

    if (error.contains('validation') || error.contains('validación')) {
      return '📋 Error de validación. Verifique los datos ingresados.';
    }

    return '❌ Ocurrió un error. Por favor, intente nuevamente.';
  }

  static bool isNetworkError(String error) {
    final e = error.toLowerCase();
    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout') ||
        e.contains('host lookup');
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String technicalError,
    bool showRetryButton = false,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isNetworkError(technicalError)
                  ? Icons.wifi_off
                  : Icons.error_outline,
              color: isNetworkError(technicalError)
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isNetworkError(technicalError) ? 'Problema de Conexión' : title,
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getFriendlyErrorMessage(technicalError),
              style: const TextStyle(fontSize: 14),
            ),
            if (isNetworkError(technicalError)) const SizedBox(height: 12),
            if (isNetworkError(technicalError))
              const Text(
                '📡 Verifique su conexión a internet e intente nuevamente.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
          ],
        ),
        actions: [
          if (showRetryButton && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static void showSuccessSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/utils/download_with_progress.dart\n```

\n```\n
\n## Archivo: lib/utils/error_messages.dart\n```
class ErrorMessages {
  // Errores de conexión/red
  static const String noInternet =
      'No hay conexión a internet. Por favor, verifica tu conexión y vuelve a intentar.';
  static const String connectionTimeout =
      'El servidor está tardando demasiado en responder. Por favor, intenta de nuevo más tarde.';
  static const String serverUnreachable =
      'No se puede conectar con el servidor. Verifica que estés conectado a la red correcta.';
  static const String networkError =
      'Error de red. Por favor, verifica tu conexión.';

  // Errores HTTP
  static const String badRequest =
      'La solicitud no es válida. Por favor, verifica los datos ingresados.';
  static const String unauthorized =
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  static const String forbidden =
      'No tienes permiso para realizar esta acción.';
  static const String notFound =
      'El recurso solicitado no existe o ha sido eliminado.';
  static const String serverError =
      'Error en el servidor. Nuestro equipo ha sido notificado. Por favor, intenta más tarde.';
  static const String serviceUnavailable =
      'El servicio no está disponible temporalmente. Estamos trabajando para resolverlo.';

  // Errores específicos de la aplicación
  static const String invalidCredentials =
      'Correo o contraseña incorrectos. Por favor, verifica tus credenciales.';
  static const String emailAlreadyExists =
      'Este correo electrónico ya está registrado.';
  static const String weakPassword =
      'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
  static const String invalidEmail = 'El correo electrónico no es válido.';
  static const String userNotFound = 'Usuario no encontrado.';
  static const String validationError =
      'Por favor, completa todos los campos requeridos correctamente.';
  static const String dataNotFound = 'No se encontraron datos.';

  // Errores generales
  static const String unexpectedError =
      'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
  static const String dataProcessingError =
      'Error al procesar los datos. Por favor, verifica la información.';
  static const String operationFailed =
      'La operación no pudo completarse. Por favor, intenta de nuevo.';

  // Mensajes específicos para trabajadores
  static const String workerNotFound =
      'El trabajador no existe o ha sido eliminado.';
  static const String duplicateCarnet =
      'El número de carnet ya existe. Por favor, use uno diferente.';
  static const String duplicatePhone =
      'El número de teléfono ya está registrado.';
  static const String duplicateEmail =
      'El correo electrónico ya está registrado.';
  static const String workersLoadFailed =
      'No se pudieron cargar los trabajadores.';
  static const String workerCreateFailed = 'No se pudo crear el trabajador.';
  static const String workerUpdateFailed =
      'No se pudo actualizar el trabajador.';
  static const String workerDeleteFailed = 'No se pudo eliminar el trabajador.';

  // Mensajes específicos para departamentos
  static const String departmentNotFound =
      'El departamento no existe o ha sido eliminado.';
  static const String duplicateDepartmentName =
      'Ya existe un departamento con ese nombre.';
  static const String duplicateDepartmentPhone =
      'Ya existe un departamento con ese teléfono.';
  static const String departmentHasWorkers =
      'No se puede eliminar el departamento porque tiene trabajadores asignados. Reasigna los trabajadores primero.';
  static const String departmentsLoadFailed =
      'No se pudieron cargar los departamentos.';
  static const String departmentCreateFailed =
      'No se pudo crear el departamento.';
  static const String departmentUpdateFailed =
      'No se pudo actualizar el departamento.';
  static const String departmentDeleteFailed =
      'No se pudo eliminar el departamento.';

  // Agregar esto a tu archivo error_messages.dart existente

  // Mensajes específicos para locales
  static const String localNotFound = 'El local no existe o ha sido eliminado.';
  static const String duplicateLocalName = 'Ya existe un local con ese nombre.';
  static const String duplicateLocalPhone =
      'Ya existe un local con ese teléfono.';
  static const String localHasWorkers =
      'No se puede eliminar el local porque tiene trabajadores asignados. Reasigna los trabajadores primero.';
  static const String localsLoadFailed = 'No se pudieron cargar los locales.';
  static const String localCreateFailed = 'No se pudo crear el local.';
  static const String localUpdateFailed = 'No se pudo actualizar el local.';
  static const String localDeleteFailed = 'No se pudo eliminar el local.';

  // Mensajes específicos para usuarios
  static const String duplicateUsername = 'El nombre de usuario ya existe.';
  static const String duplicateUserEmail =
      'El correo electrónico ya está registrado.';
  static const String weakUserPassword =
      'La contraseña debe tener al menos 6 caracteres.';
  static const String currentPasswordIncorrect =
      'La contraseña actual es incorrecta.';
  static const String newPasswordInvalid =
      'La nueva contraseña no cumple los requisitos de seguridad.';
  static const String lastAdminCannotDelete =
      'No se puede eliminar el último administrador del sistema.';
  static const String usersLoadFailed = 'No se pudieron cargar los usuarios.';
  static const String userCreateFailed = 'No se pudo crear el usuario.';
  static const String userUpdateFailed = 'No se pudo actualizar el usuario.';
  static const String userDeleteFailed = 'No se pudo eliminar el usuario.';
  static const String userRoleUpdateFailed =
      'No se pudieron actualizar los roles del usuario.';

  // Agregar esto a tu archivo error_messages.dart existente

  // Mensajes específicos para efemérides
  static const String efemerideNotFound =
      'La efeméride no existe o ha sido eliminada.';
  static const String efemerideInvalidDate =
      'La fecha de la efeméride no es válida.';
  static const String efemerideDataRequired =
      'El dato de la efeméride es requerido.';
  static const String efemeridesLoadFailed =
      'No se pudieron cargar las efemérides.';
  static const String efemerideCreateFailed = 'No se pudo crear la efeméride.';
  static const String efemerideUpdateFailed =
      'No se pudo actualizar la efeméride.';
  static const String efemerideDeleteFailed =
      'No se pudo eliminar la efeméride.';
  static const String efemerideDuplicate =
      'Ya existe una efeméride para esta fecha con el mismo dato.';
  // Mensajes para diálogos
  static const String saveFailed = 'No se pudo guardar los cambios.';
  static const String deleteFailed = 'No se pudo eliminar el registro.';
  static const String loadFailed = 'No se pudieron cargar los datos.';
  static const String validationFailed =
      'Error de validación. Verifique los datos.';

  // Mensajes de éxito
  static const String saveSuccess = 'Guardado exitosamente';
  static const String deleteSuccess = 'Eliminado exitosamente';
  static const String createSuccess = 'Creado exitosamente';
  static const String updateSuccess = 'Actualizado exitosamente';

  // Sugerencias
  static const String networkSuggestion =
      'Verifique su conexión a internet e intente nuevamente.';
  static const String validationSuggestion =
      'Revise los campos marcados con error.';
  static const String serverSuggestion =
      'El problema puede ser temporal. Intente más tarde.';

  // Método para obtener sugerencia según error
  static String getSuggestion(String error) {
    final e = error.toLowerCase();

    if (e.contains('conexión') ||
        e.contains('network') ||
        e.contains('socket')) {
      return networkSuggestion;
    }

    if (e.contains('validation') ||
        e.contains('validación') ||
        e.contains('invalid')) {
      return validationSuggestion;
    }

    if (e.contains('500') || e.contains('server') || e.contains('timeout')) {
      return serverSuggestion;
    }

    return 'Por favor, intente nuevamente.';
  }

  // Mensajes específicos para trabajadores
  static const String duplicateWorkerPhone =
      'El número de teléfono ya está registrado.';
  static const String invalidBirthday = 'La fecha de cumpleaños no es válida.';
  static const String invalidCarnetFormat =
      'El carnet debe tener 11 dígitos numéricos.';
  static const String carnetProvinceInvalid =
      'Los primeros dígitos no corresponden a una provincia válida.';
  static const String birthdayFutureDate =
      'La fecha de cumpleaños no puede ser futura.';

  // Mensajes específicos para efemérides
  static const String duplicateEfemerideDate =
      'Ya existe una efeméride para esta fecha con el mismo dato.';
  static const String duplicateEfemerideName =
      'Ya existe una efeméride con este nombre.';

  // Sugerencias específicas
  static const String carnetSuggestion =
      'El carnet debe tener 11 dígitos. Los primeros 2 dígitos representan la provincia.';
  static const String phoneSuggestion =
      'Formato: +53 XXX XXXXXX. Use solo números y el código de país.';
  static const String dateSuggestion =
      'Use el formato YYYY-MM-DD (Ej: 1990-05-15).';
  static const String birthdaySuggestion =
      'La fecha no puede ser futura y debe ser real.';
  // Método para obtener mensaje según código HTTP
  static String fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return badRequest;
      case 401:
        return unauthorized;
      case 403:
        return forbidden;
      case 404:
        return notFound;
      case 500:
        return serverError;
      case 503:
        return serviceUnavailable;
      default:
        if (statusCode >= 500) {
          return serverError;
        } else if (statusCode >= 400) {
          return badRequest;
        }
        return unexpectedError;
    }
  }

  // Método para obtener mensaje según tipo de excepción
  static String fromException(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('host lookup')) {
      return noInternet;
    }

    if (errorString.contains('timeout')) {
      return connectionTimeout;
    }

    if (errorString.contains('format') || errorString.contains('json')) {
      return dataProcessingError;
    }

    if (errorString.contains('credentials') || errorString.contains('auth')) {
      return invalidCredentials;
    }

    if (errorString.contains('email already')) {
      return emailAlreadyExists;
    }

    return unexpectedError;
  }
}
\n```\n
\n## Archivo: lib/utils/excel_import_service.dart\n```
import 'dart:io';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ExcelImportService {
  static Future<List<List<dynamic>>> readRowsFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('El archivo no existe.');
    }

    final bytes = await file.readAsBytes();
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);

    if (decoder.tables.isEmpty) {
      throw Exception('No se encontró una hoja válida en el archivo.');
    }

    final table = decoder.tables.values.first;
    final rows = <List<dynamic>>[];

    for (final row in table.rows) {
      rows.add(row.map((value) => value ?? '').toList());
    }

    return rows;
  }

  static List<Map<String, dynamic>> parseSimpleRows({
    required List<List<dynamic>> rows,
    required List<String> requiredColumns,
  }) {
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first;
    final normalizedHeaders = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final rawHeader = headerRow[i]?.toString().trim() ?? '';
      final normalizedHeader = _normalizeHeader(rawHeader);
      if (normalizedHeader.isNotEmpty) {
        normalizedHeaders[normalizedHeader] = i;
      }
    }

    final parsedRows = <Map<String, dynamic>>[];

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final isEmpty = row.every((value) => value.toString().trim().isEmpty);
      if (isEmpty) {
        continue;
      }

      final mappedRow = <String, dynamic>{};
      for (final requiredColumn in requiredColumns) {
        final columnIndex = _findColumnIndex(
          normalizedHeaders: normalizedHeaders,
          requiredColumn: requiredColumn,
        );
        if (columnIndex == null) {
          continue;
        }
        final value = row.length > columnIndex ? row[columnIndex] : '';
        mappedRow[requiredColumn] = value?.toString().trim() ?? '';
      }

      if (mappedRow.values.any((value) => value.toString().trim().isNotEmpty)) {
        parsedRows.add(mappedRow);
      }
    }

    return parsedRows;
  }

  static int? _findColumnIndex({
    required Map<String, int> normalizedHeaders,
    required String requiredColumn,
  }) {
    final normalizedRequiredColumn = _normalizeHeader(requiredColumn);
    if (normalizedRequiredColumn.isEmpty) {
      return null;
    }

    if (normalizedHeaders.containsKey(normalizedRequiredColumn)) {
      return normalizedHeaders[normalizedRequiredColumn];
    }

    for (final alias in _columnAliases(requiredColumn)) {
      if (normalizedHeaders.containsKey(alias)) {
        return normalizedHeaders[alias];
      }
    }

    return null;
  }

  static List<String> _columnAliases(String requiredColumn) {
    final normalized = _normalizeHeader(requiredColumn);
    switch (normalized) {
      case 'nombre':
        return ['nombrecompleto', 'nombreyapellido', 'nombres', 'fullname'];
      case 'apellido':
        return ['apellidos', 'lastname'];
      case 'carnet':
        return ['carnetidentidad', 'carnetdeidentidad', 'carnetid', 'ci'];
      case 'telefono':
        return ['telefonocelular', 'numerocelular', 'celular', 'phone', 'mobile'];
      case 'direccion':
        return ['domicilio', 'direccionpersonal', 'address'];
      case 'departamento':
        return ['departamentos', 'area'];
      case 'local':
        return ['sucursal', 'ubicacion', 'branch'];
      case 'fechacumpleannos':
        return ['fechadenacimiento', 'cumpleannos', 'birthday'];
      default:
        return [];
    }
  }

  static String _normalizeHeader(String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .split('')
        .map((char) {
          switch (char) {
            case 'á':
            case 'à':
            case 'ä':
            case 'â':
              return 'a';
            case 'é':
            case 'è':
            case 'ë':
            case 'ê':
              return 'e';
            case 'í':
            case 'ì':
            case 'ï':
            case 'î':
              return 'i';
            case 'ó':
            case 'ò':
            case 'ö':
            case 'ô':
              return 'o';
            case 'ú':
            case 'ù':
            case 'ü':
            case 'û':
              return 'u';
            case 'ñ':
              return 'n';
            case 'ç':
              return 'c';
            default:
              return char;
          }
        })
        .join('')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');

    return normalized;
  }
}
\n```\n
\n## Archivo: lib/utils/excel_template_service.dart\n```
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExcelTemplateService {
  static Future<String?> generateWorkersTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_trabajadores.xlsx',
      sheetName: 'Trabajadores',
      title: 'Plantilla para importar trabajadores',
      instructions: [
        '1. Completa las columnas obligatorias.',
        '2. El campo nombre y carnet son obligatorios.',
        '3. Los campos departamento y local deben coincidir con los nombres existentes.',
        '4. Usa fechas como 15 de mayo o 2024-05-15.',
      ],
      headers: [
        'nombre',
        'apellido',
        'carnet',
        'telefono',
        'direccion',
        'departamento',
        'local',
        'fechaCumpleannos',
      ],
      sampleRows: [
        [
          'Juan',
          'Pérez',
          'JP001',
          '555-1234',
          'Calle 123',
          'Ventas',
          'Sucursal Centro',
          '15 de mayo',
        ],
      ],
    );
  }

  static Future<String?> generateLocalsTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_locales.xlsx',
      sheetName: 'Locales',
      title: 'Plantilla para importar locales',
      instructions: [
        '1. Completa el nombre del local.',
        '2. El teléfono es opcional.',
        '3. Cada fila representa un local nuevo.',
      ],
      headers: ['nombre', 'telefono'],
      sampleRows: [
        ['Sucursal Centro', '555-1111'],
      ],
    );
  }

  static Future<String?> generateDepartmentsTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_departamentos.xlsx',
      sheetName: 'Departamentos',
      title: 'Plantilla para importar departamentos',
      instructions: [
        '1. Completa el nombre del departamento.',
        '2. El teléfono es opcional.',
        '3. Cada fila representa un departamento nuevo.',
      ],
      headers: ['nombre', 'telefono'],
      sampleRows: [
        ['Ventas', '555-2222'],
      ],
    );
  }

  static Future<String?> _generateTemplate({
    required String fileName,
    required String sheetName,
    required String title,
    required List<String> instructions,
    required List<String> headers,
    required List<List<dynamic>> sampleRows,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('La generación de plantillas no está disponible en web.');
    }

    try {
      final excel = Excel.createExcel();
      final instructionsSheet = excel['Instrucciones'];
      _writeRow(instructionsSheet, 0, ['Plantilla de importación']);
      _writeRow(instructionsSheet, 1, [title]);
      _writeRow(instructionsSheet, 3, ['Instrucciones']);

      for (var i = 0; i < instructions.length; i++) {
        _writeRow(instructionsSheet, 4 + i, [instructions[i]]);
      }

      _writeRow(instructionsSheet, 8, ['Columnas esperadas']);
      for (var i = 0; i < headers.length; i++) {
        _writeRow(instructionsSheet, 9 + i, [headers[i]]);
      }

      final dataSheet = excel[sheetName];
      _writeRow(dataSheet, 0, headers);

      for (var i = 0; i < sampleRows.length; i++) {
        _writeRow(dataSheet, i + 1, sampleRows[i]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('No se pudo generar el archivo Excel.');
      }

      final directory = await _getOutputDirectory();
      if (directory == null) {
        throw Exception('No se pudo obtener un directorio para guardar la plantilla.');
      }

      final file = File(p.join(directory.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw Exception('Error al generar la plantilla: $e');
    }
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values) {
    for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
      final value = values[columnIndex].toString();
      sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
      ).value = TextCellValue(value);
    }
  }

  static Future<Directory?> _getOutputDirectory() async {
    const appFolderName = 'PhoneBook';

    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final manageStatus = await Permission.manageExternalStorage.request();

        final granted = storageStatus.isGranted || manageStatus.isGranted;
        if (!granted) {
          throw Exception('Se requieren permisos de almacenamiento para guardar archivos.');
        }

        final rootDir = Directory('/storage/emulated/0');
        if (await rootDir.exists()) {
          final appDir = Directory(p.join(rootDir.path, appFolderName));
          await appDir.create(recursive: true);
          return appDir;
        }
      }

      if (Platform.isIOS) {
        final baseDir = await getApplicationDocumentsDirectory();
        final appDir = Directory(p.join(baseDir.path, appFolderName));
        await appDir.create(recursive: true);
        return appDir;
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final appDir = Directory(p.join(downloadsDir.path, appFolderName));
          await appDir.create(recursive: true);
          return appDir;
        }
      }

      final fallbackDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(p.join(fallbackDir.path, appFolderName));
      await appDir.create(recursive: true);
      return appDir;
    } catch (_) {
      return null;
    }
  }
}
\n```\n
\n## Archivo: lib/utils/notification_utils.dart\n```
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
\n```\n
\n## Archivo: lib/utils/responsive_utils.dart\n```
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Método para detectar el tipo de pantalla
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 900) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Método para obtener tamaño responsive
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.2;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.5;
    }
  }

  // Método para obtener padding responsive
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return EdgeInsets.all(16);
      case ScreenType.tablet:
        return EdgeInsets.all(24);
      case ScreenType.desktop:
        return EdgeInsets.all(32);
    }
  }

  // Método para obtener tamaño de texto responsive
  static double getResponsiveTextSize(BuildContext context, double baseSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSize;
      case ScreenType.tablet:
        return baseSize * 1.1;
      case ScreenType.desktop:
        return baseSize * 1.2;
    }
  }

  // Método para grid responsive
  static int getResponsiveGridCount(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 2;
      case ScreenType.tablet:
        return 3;
      case ScreenType.desktop:
        return 4;
    }
  }
}

enum ScreenType { mobile, tablet, desktop }
\n```\n
\n## Archivo: lib/utils/specific_validators.dart\n```
import 'error_messages.dart';

class SpecificValidators {
  // Validación específica para carnet de identidad cubano
  static String? validateCarnetID(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmedValue = value.trim();

    // Debe tener exactamente 11 dígitos
    if (trimmedValue.length != 11) {
      return ErrorMessages.invalidCarnetFormat;
    }

    // Solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (!onlyNumbersRegex.hasMatch(trimmedValue)) {
      return ErrorMessages.invalidCarnetFormat;
    }

    // Validar provincia (01-16 para Cuba)
    final provinceCode = int.tryParse(trimmedValue.substring(0, 2));
    if (provinceCode == null || provinceCode < 1 || provinceCode > 16) {
      return ErrorMessages.carnetProvinceInvalid;
    }

    return null;
  }

  // Validación específica para fecha de cumpleaños
  static String? validateBirthday(String? value, {bool required = false}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return required ? 'La fecha de cumpleaños es requerida' : null;
    }

    final trimmedValue = value.trim();

    // Verificar formato YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(trimmedValue)) {
      return 'Formato inválido. Use YYYY-MM-DD';
    }

    try {
      final parts = trimmedValue.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Validaciones básicas
      if (year < 1900 || year > DateTime.now().year) {
        return 'Año inválido (1900-${DateTime.now().year})';
      }

      if (month < 1 || month > 12) {
        return 'Mes inválido (1-12)';
      }

      // Validar días según el mes
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        return 'Día inválido para el mes seleccionado';
      }

      // No permitir fechas futuras
      final birthday = DateTime(year, month, day);
      if (birthday.isAfter(DateTime.now())) {
        return ErrorMessages.birthdayFutureDate;
      }

      // No permitir edades extremas (opcional)
      final age = DateTime.now().year - year;
      if (age > 120) {
        return 'Edad no válida';
      }
    } catch (e) {
      return 'Fecha inválida';
    }

    return null;
  }

  // Validación específica para fecha de efeméride
  static String? validateEfemerideDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);

      // Verificar que la fecha creada coincida
      if (date.year != year || date.month != month || date.day != day) {
        return ErrorMessages.efemerideInvalidDate;
      }

      // Opcional: no permitir fechas muy antiguas o futuras extremas
      if (year < 1000 || year > 2100) {
        return 'El año debe estar entre 1000 y 2100';
      }

      return null;
    } catch (e) {
      return ErrorMessages.efemerideInvalidDate;
    }
  }
}
\n```\n
\n## Archivo: lib/utils/update_config.dart\n```
class UpdateConfig {
  // URL del archivo JSON que contiene la información de actualización
  static const String updateJsonUrl =
      'http://ftp.scu.desoft.cu/files/PhoneBook/';

  // Tiempo en horas entre verificaciones automáticas
  static const int checkIntervalHours = 24;

  // Nombre del archivo para guardar la última verificación
  static const String lastCheckKey = 'last_update_check';

  // Clave para guardar si el usuario ignoró una actualización
  static const String ignoredUpdateKey = 'ignored_update_version';

  // Tiempo máximo de caché para la información de actualización (en segundos)
  static const int cacheDurationSeconds = 3600; // 1 hora

  static const int notificationCooldownHours = 24;

  // AGREGAR: Tiempo mínimo entre verificaciones (en segundos)
  static const int minCheckIntervalSeconds = 3600; // 1 hora

  // AGREGAR: Modo de notificación
  static const NotificationMode notificationMode = NotificationMode.system;
}

enum NotificationMode {
  dialog, // Diálogo modal (solo para obligatorias)
  system, // Notificación del sistema
  snackbar, // Snackbar en la parte inferior
}
\n```\n
\n## Archivo: lib/utils/validators.dart\n```
class Validators {
  // Valida si es un email válido
  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'El email es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'El email es requerido' : null;
    }

    // Expresión regular mejorada para email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,255}\.[a-zA-Z]{2,63}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Ingrese un email válido (ejemplo: usuario@dominio.com)';
    }

    // Validación adicional de estructura
    if (trimmedValue.contains('..')) {
      return 'El email no puede contener puntos consecutivos';
    }

    if (trimmedValue.startsWith('.') || trimmedValue.endsWith('.')) {
      return 'El email no puede comenzar o terminar con punto';
    }

    final parts = trimmedValue.split('@');
    if (parts.length != 2) {
      return 'Formato de email inválido';
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Validar longitud del local part
    if (localPart.length > 64) {
      return 'La parte local del email no puede exceder 64 caracteres';
    }

    // Validar que el dominio tenga al menos un punto
    if (!domainPart.contains('.')) {
      return 'El dominio del email debe contener un punto';
    }

    return null;
  }

  // Valida username (para registro)
  static String? validateUsername(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'El nombre de usuario es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'El nombre de usuario es requerido' : null;
    }

    // Longitud
    if (trimmedValue.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }

    if (trimmedValue.length > 30) {
      return 'El nombre de usuario no puede exceder 30 caracteres';
    }

    // Caracteres permitidos: letras, números, guiones bajos y puntos
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(trimmedValue)) {
      return 'Solo se permiten letras, números, puntos y guiones bajos (_)';
    }

    // No puede comenzar o terminar con punto o guión bajo
    if (trimmedValue.startsWith('.') || trimmedValue.startsWith('_')) {
      return 'No puede comenzar con punto o guión bajo';
    }

    if (trimmedValue.endsWith('.') || trimmedValue.endsWith('_')) {
      return 'No puede terminar con punto o guión bajo';
    }

    // No puede tener puntos o guiones bajos consecutivos
    if (trimmedValue.contains('..') || trimmedValue.contains('__')) {
      return 'No puede tener puntos o guiones bajos consecutivos';
    }

    // No puede ser solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (onlyNumbersRegex.hasMatch(trimmedValue)) {
      return 'El nombre de usuario no puede ser solo números';
    }

    return null;
  }

  // Valida campo de login (puede ser username o email)
  static String? validateUsernameOrEmail(
    String? value, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Usuario o email es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'Usuario o email es requerido' : null;
    }

    // Longitud mínima
    if (trimmedValue.length < 3) {
      return 'Debe tener al menos 3 caracteres';
    }

    // Longitud máxima
    if (trimmedValue.length > 254) {
      // Longitud máxima para email según RFC
      return 'No puede exceder 254 caracteres';
    }

    // Si parece un email, validar como email
    if (trimmedValue.contains('@')) {
      return validateEmail(trimmedValue, required: required);
    }

    // Si no contiene @, validar como username (pero con reglas más flexibles para login)
    if (trimmedValue.length > 50) {
      return 'El nombre de usuario no puede exceder 50 caracteres';
    }

    // Para login, ser más permisivo con el username
    final loginUsernameRegex = RegExp(r'^[a-zA-Z0-9_.@\-+]+$');
    if (!loginUsernameRegex.hasMatch(trimmedValue)) {
      return 'Caracteres no válidos detectados';
    }

    return null;
  }

  // Valida contraseña
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'La contraseña es requerida' : null;
    }

    // Longitud
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña no puede exceder 128 caracteres';
    }

    // Seguridad básica (opcional, puedes ajustar según necesidades)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return 'Para mayor seguridad, incluye letras y números';
    }

    // Verificar espacios
    if (value.contains(' ')) {
      return 'La contraseña no puede contener espacios';
    }

    return null;
  }

  // Valida confirmación de contraseña
  static String? validateConfirmPassword(
    String? value,
    String password, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Confirme la contraseña' : null;
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Valida campo requerido genérico
  static String? validateRequired(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final trimmedValue = value.trim();

    if (minLength != null && trimmedValue.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    if (maxLength != null && trimmedValue.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }

  // Valida teléfono
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'El teléfono es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty && !required) {
      return null;
    }

    // Eliminar espacios, guiones y paréntesis para validación
    final cleanPhone = trimmedValue.replaceAll(RegExp(r'[\s\-()]'), '');

    // Solo números y posible signo + al inicio
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Ingrese un número de teléfono válido (7-15 dígitos)';
    }

    // Validar que no sea todo el mismo número
    final allSameDigits = RegExp(
      r'^(\d)\1+$',
    ).hasMatch(cleanPhone.replaceAll('+', ''));
    if (allSameDigits) {
      return 'El número de teléfono no parece válido';
    }

    return null;
  }

  // Valida formato de nombre (para nombres de personas)
  static String? validateName(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? '$fieldName es requerido' : null;
    }

    // Longitud
    if (trimmedValue.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }

    if (trimmedValue.length > 50) {
      return '$fieldName no puede exceder 50 caracteres';
    }

    // Solo letras, espacios y algunos caracteres especiales permitidos
    final nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-.,]+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return '$fieldName solo puede contener letras y espacios';
    }

    // No puede tener múltiples espacios consecutivos
    if (trimmedValue.contains('  ')) {
      return '$fieldName no puede tener múltiples espacios consecutivos';
    }

    return null;
  }
}
\n```\n
\n## Archivo: lib/widgets/calendar/efemeride_dialog.dart\n```
// import 'package:flutter/material.dart';
// import '../../models/efemeride.dart';

// class EfemerideDialog extends StatefulWidget {
//   final Efemeride? efemeride;
//   final Function(Efemeride) onSave;

//   const EfemerideDialog({super.key, this.efemeride, required this.onSave});

//   @override
//   State<EfemerideDialog> createState() => _EfemerideDialogState();
// }

// class _EfemerideDialogState extends State<EfemerideDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _datoController = TextEditingController();
//   final _detalleController = TextEditingController();
//   final _yearController = TextEditingController();

//   int _selectedDay = 1;
//   int _selectedMonth = 1;

//   final List<String> _months = [
//     'Enero',
//     'Febrero',
//     'Marzo',
//     'Abril',
//     'Mayo',
//     'Junio',
//     'Julio',
//     'Agosto',
//     'Septiembre',
//     'Octubre',
//     'Noviembre',
//     'Diciembre',
//   ];

//   final List<int> _days = List.generate(31, (index) => index + 1);

//   @override
//   void initState() {
//     super.initState();

//     if (widget.efemeride != null) {
//       // Modo edición: cargar datos existentes
//       _datoController.text = widget.efemeride!.dato;
//       _detalleController.text = widget.efemeride!.detalle;
//       _selectedDay = widget.efemeride!.fecha.day;
//       _selectedMonth = widget.efemeride!.fecha.month;
//       _yearController.text = widget.efemeride!.fecha.year.toString();
//     } else {
//       // Modo agregar: valores por defecto
//       _yearController.text = DateTime.now().year.toString();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isEditMode = widget.efemeride != null;
//     final title = isEditMode ? 'Editar Efeméride' : 'Agregar Efeméride';
//     final buttonText = isEditMode ? 'Guardar Cambios' : 'Guardar';

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.9,
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         padding: EdgeInsets.all(20),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     isEditMode ? Icons.edit : Icons.history,
//                     color: Colors.blue[700],
//                     size: 24,
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 16),

//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Selector de fecha
//                     Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Fecha de la efeméride',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                               fontSize: 14,
//                             ),
//                           ),
//                           SizedBox(height: 8),

//                           // Día
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Día',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedDay,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                   ),
//                                   items: _days.map((int day) {
//                                     return DropdownMenuItem<int>(
//                                       value: day,
//                                       child: Text(
//                                         '$day',
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     );
//                                   }).toList(),
//                                   onChanged: (int? newValue) {
//                                     if (newValue != null) {
//                                       setState(() {
//                                         _selectedDay = newValue;
//                                       });
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Mes
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Mes',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedMonth,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                   ),
//                                   items: _months.asMap().entries.map((entry) {
//                                     return DropdownMenuItem<int>(
//                                       value: entry.key + 1,
//                                       child: Text(
//                                         entry.value,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     );
//                                   }).toList(),
//                                   onChanged: (int? newValue) {
//                                     if (newValue != null) {
//                                       setState(() {
//                                         _selectedMonth = newValue;
//                                       });
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Año
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Año',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               TextFormField(
//                                 controller: _yearController,
//                                 keyboardType: TextInputType.number,
//                                 decoration: InputDecoration(
//                                   hintText: 'Ej: 2024',
//                                   contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Ingresa el año';
//                                   }
//                                   final year = int.tryParse(value);
//                                   if (year == null) {
//                                     return 'Año inválido';
//                                   }
//                                   if (year < 1000 || year > 9999) {
//                                     return 'Año debe ser entre 1000 y 9999';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Información
//                           Container(
//                             padding: EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.amber[50],
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(color: Colors.amber[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.info,
//                                   size: 16,
//                                   color: Colors.amber[700],
//                                 ),
//                                 SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     isEditMode
//                                         ? 'Nota: El año original se guarda, pero la efeméride se muestra anualmente'
//                                         : 'Las efemérides se mostrarán anualmente en el calendario',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.amber[800],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     SizedBox(height: 16),

//                     TextFormField(
//                       controller: _datoController,
//                       decoration: InputDecoration(
//                         labelText: 'Nombre de la efeméride *',
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Por favor ingresa el nombre';
//                         }
//                         return null;
//                       },
//                     ),

//                     SizedBox(height: 16),

//                     TextFormField(
//                       controller: _detalleController,
//                       maxLines: 3,
//                       decoration: InputDecoration(
//                         labelText: 'Descripción',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Por favor ingresa una descripción';
//                         }
//                         return null;
//                       },
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 20),

//               // Botones
//               LayoutBuilder(
//                 builder: (context, constraints) {
//                   final isSmall = constraints.maxWidth < 300;

//                   if (isSmall) {
//                     return Column(
//                       children: [
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _handleSave,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[700],
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               buttonText,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         SizedBox(
//                           width: double.infinity,
//                           child: TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Cancelar',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   } else {
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Cancelar',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: _handleSave,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[700],
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               buttonText,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleSave() {
//     if (_formKey.currentState!.validate()) {
//       final year = int.tryParse(_yearController.text);
//       if (year == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Año inválido'), backgroundColor: Colors.red),
//         );
//         return;
//       }

//       final fecha = DateTime(year, _selectedMonth, _selectedDay);

//       final efemeride = widget.efemeride != null
//           ? widget.efemeride!.copyWith(
//               fecha: fecha,
//               dato: _datoController.text.trim(),
//               detalle: _detalleController.text.trim(),
//             )
//           : Efemeride(
//               id: 0,
//               fecha: fecha,
//               dato: _datoController.text.trim(),
//               detalle: _detalleController.text.trim(),
//             );

//       widget.onSave(efemeride);
//       Navigator.of(context).pop();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             widget.efemeride != null
//                 ? 'Efeméride actualizada exitosamente'
//                 : 'Efeméride agregada exitosamente',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _datoController.dispose();
//     _detalleController.dispose();
//     _yearController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import '../../models/efemeride.dart';
import '../../utils/validators.dart';

class EfemerideDialog extends StatefulWidget {
  final Efemeride? efemeride;
  final Function(Efemeride) onSave;

  const EfemerideDialog({super.key, this.efemeride, required this.onSave});

  @override
  State<EfemerideDialog> createState() => _EfemerideDialogState();
}

class _EfemerideDialogState extends State<EfemerideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _datoController = TextEditingController();
  final _detalleController = TextEditingController();
  final _yearController = TextEditingController();

  int _selectedDay = 1;
  int _selectedMonth = 1;
  // bool _isSaving = false;

  final List<String> _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  // Validar día según mes seleccionado
  List<int> get _availableDays {
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final daysInMonth = DateTime(year, _selectedMonth + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  @override
  void initState() {
    super.initState();

    if (widget.efemeride != null) {
      _datoController.text = widget.efemeride!.dato;
      _detalleController.text = widget.efemeride!.detalle;
      _selectedDay = widget.efemeride!.fecha.day;
      _selectedMonth = widget.efemeride!.fecha.month;
      _yearController.text = widget.efemeride!.fecha.year.toString();
    } else {
      final now = DateTime.now();
      _selectedDay = now.day;
      _selectedMonth = now.month;
      _yearController.text = now.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.efemeride != null;
    final availableDays = _availableDays;

    // Asegurarse de que el día seleccionado sea válido para el mes
    if (!availableDays.contains(_selectedDay)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDay = availableDays.first;
        });
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit : Icons.history,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditMode ? 'Editar Efeméride' : 'Agregar Efeméride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Selector de fecha
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de la efeméride *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Día
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Día *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedDay,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: availableDays.map((int day) {
                                    return DropdownMenuItem<int>(
                                      value: day,
                                      child: Text(
                                        '$day',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedDay = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Seleccione un día';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Mes
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedMonth,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _months.asMap().entries.map((entry) {
                                    return DropdownMenuItem<int>(
                                      value: entry.key + 1,
                                      child: Text(
                                        entry.value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedMonth = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Seleccione un mes';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Año
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Año *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Ej: 2024',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  // Actualizar días disponibles cuando cambie el año
                                  if (value.length == 4) {
                                    setState(() {});
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa el año';
                                  }
                                  final year = int.tryParse(value);
                                  if (year == null) {
                                    return 'Año inválido';
                                  }
                                  if (year < 1000 || year > 9999) {
                                    return 'Año debe ser entre 1000 y 9999';
                                  }

                                  // Verificar que la fecha sea válida
                                  try {
                                    final date = DateTime(
                                      year,
                                      _selectedMonth,
                                      _selectedDay,
                                    );
                                    if (date.year != year ||
                                        date.month != _selectedMonth ||
                                        date.day != _selectedDay) {
                                      return 'Fecha inválida para este año';
                                    }
                                  } catch (e) {
                                    return 'Fecha inválida';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nombre de la efeméride
                    TextFormField(
                      controller: _datoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la efeméride *',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Día de la Independencia',
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'El nombre de la efeméride',
                        minLength: 3,
                        maxLength: 100,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _detalleController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Descripción detallada del evento...',
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'La descripción',
                        minLength: 10,
                        maxLength: 500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isEditMode ? 'Guardar Cambios' : 'Agregar',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _handleSave() {
  //   if (_formKey.currentState!.validate()) {
  //     final year = int.tryParse(_yearController.text);
  //     if (year == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Año inválido'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       return;
  //     }

  //     final fecha = DateTime(year, _selectedMonth, _selectedDay);

  //     final efemeride = widget.efemeride != null
  //         ? widget.efemeride!.copyWith(
  //             fecha: fecha,
  //             dato: _datoController.text.trim(),
  //             detalle: _detalleController.text.trim(),
  //           )
  //         : Efemeride(
  //             id: 0,
  //             fecha: fecha,
  //             dato: _datoController.text.trim(),
  //             detalle: _detalleController.text.trim(),
  //           );

  //     widget.onSave(efemeride);
  //     Navigator.of(context).pop();
  //   }
  // }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_yearController.text);
    if (year == null) {
      _showErrorSnackbar('Año inválido');
      return;
    }

    try {
      // setState(() => _isSaving = true);

      final fecha = DateTime(year, _selectedMonth, _selectedDay);
      final efemeride = widget.efemeride != null
          ? widget.efemeride!.copyWith(
              fecha: fecha,
              dato: _datoController.text.trim(),
              detalle: _detalleController.text.trim(),
            )
          : Efemeride(
              id: 0,
              fecha: fecha,
              dato: _datoController.text.trim(),
              detalle: _detalleController.text.trim(),
            );

      // Intentar guardar
      await widget.onSave(efemeride);

      // Si llega aquí, fue exitoso
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showSuccessSnackbar(
        widget.efemeride != null
            ? '✅ Efeméride actualizada exitosamente'
            : '✅ Efeméride creada exitosamente',
      );
    } catch (e) {
      // Manejar el error
      _showErrorDialog(
        'No se pudo ${widget.efemeride != null ? 'actualizar' : 'crear'} la efeméride',
        e.toString(),
      );
    } finally {
      if (mounted) {
        // setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getFriendlyErrorMessage(message),
              style: const TextStyle(fontSize: 14),
            ),
            if (_isNetworkError(message)) const SizedBox(height: 12),
            if (_isNetworkError(message))
              const Text(
                '📡 Sugerencia: Verifique su conexión a internet e intente nuevamente.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String _getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network')) {
      return '❌ Error de conexión. No se pudo conectar con el servidor.';
    }

    if (error.contains('timeout')) {
      return '⏰ El servidor está tardando demasiado en responder.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return '⚠️ Ya existe una efeméride con esta fecha y nombre.';
    }

    if (error.contains('fecha') || error.contains('date')) {
      return '📅 La fecha ingresada no es válida.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return '📝 Por favor, complete todos los campos requeridos.';
    }

    if (error.contains('500') || error.contains('server')) {
      return '🔧 Error en el servidor. Por favor, intente más tarde.';
    }

    return '❌ Ocurrió un error. Por favor, intente nuevamente.';
  }

  bool _isNetworkError(String error) {
    final e = error.toLowerCase();
    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout');
  }

  // Modificar el botón de guardar en el build para mostrar loading
  // Widget _buildSaveButton(bool isEditMode) {
  //   return Expanded(
  //     child: ElevatedButton(
  //       onPressed: _isSaving ? null : _handleSave,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.blue[700],
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //       ),
  //       child: _isSaving
  //           ? const SizedBox(
  //               height: 20,
  //               width: 20,
  //               child: CircularProgressIndicator(
  //                 strokeWidth: 2,
  //                 color: Colors.white,
  //               ),
  //             )
  //           : Text(
  //               isEditMode ? 'Guardar Cambios' : 'Agregar',
  //               style: const TextStyle(
  //                 fontSize: 16,
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _datoController.dispose();
    _detalleController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/widgets/calendar/event_details_dialog.dart\n```
import 'package:flutter/material.dart';

import '../../models/event.dart';

class EventDetailsDialog extends StatelessWidget {
  final DateTime date;
  final List<Event> events;

  const EventDetailsDialog({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event, color: Colors.blue[700], size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 4),
            Text(
              '${events.length} evento${events.length > 1 ? 's' : ''} programado${events.length > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            SizedBox(height: 20),

            // Lista de eventos
            ...events.map((event) => _buildEventItem(event)),

            SizedBox(height: 20),

            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: event.type == EventType.birthday
            ? Colors.pink[50]
            : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.type == EventType.birthday
              ? Colors.pink[100]!
              : Colors.blue[100]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.type == EventType.birthday
                  ? Colors.pink[100]
                  : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.type == EventType.birthday ? Icons.cake : Icons.history,
              color: event.type == EventType.birthday
                  ? Colors.pink
                  : Colors.blue,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
                Text(
                  event.displayDate,
                  style: TextStyle(color: Colors.grey[800], fontSize: 10),
                ),
                if (event.efemeride != null) ...[
                  SizedBox(height: 4),
                  Text(
                    event.efemeride!.detalle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
\n```\n
\n## Archivo: lib/widgets/department_dialog.dart\n```
import 'package:flutter/material.dart';
import '../models/department.dart';
import '../providers/department_provider.dart';
import '../utils/dialog_error_handler.dart';
import '../utils/validators.dart';

class DepartmentDialog extends StatefulWidget {
  final Department? department;
  final Future<bool> Function(Department) onSave;
  final DepartmentProvider departmentProvider;

  const DepartmentDialog({
    super.key,
    this.department,
    required this.onSave,
    required this.departmentProvider,
  });

  @override
  DepartmentDialogState createState() => DepartmentDialogState();
}

class DepartmentDialogState extends State<DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false; // <-- AGREGAR

  @override
  void initState() {
    super.initState();
    if (widget.department != null) {
      _nameController.text = widget.department!.name;
      _phoneController.text = widget.department!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.department != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.mode_edit_rounded : Icons.work,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isEditMode ? 'Editar Departamento' : 'Agregar Departamento',
              softWrap: true,
              maxLines: 2,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del departamento
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del departamento *',
                  prefixIcon: Icon(Icons.business_center),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Recursos Humanos',
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'El nombre del departamento',
                  minLength: 2,
                  maxLength: 100,
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: +53 55567890',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? 'Guardar Cambios' : 'Agregar',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    final mode = widget.department != null ? 'EDIT' : 'CREATE';
    debugPrint('[DepartmentDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[DepartmentDialog][$mode] Validation failed');
      return;
    }

    try {
      setState(() => _isSaving = true);
      debugPrint('[DepartmentDialog][$mode] Validation passed');

      final department = Department(
        id: widget.department?.id ?? 0,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      debugPrint(
        '[DepartmentDialog][$mode] Department built: ${department.toJson()}',
      );
      debugPrint(
        '[DepartmentDialog][$mode] DTO: ${widget.department != null ? department.toUpdateDto() : department.toCreateDto()}',
      );

      // Intentar guardar
      final success = await widget.onSave(department);
      debugPrint('[DepartmentDialog][$mode] onSave returned success=$success');

      // Si llega aquí, fue exitoso
      if (success && mounted) {
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.department != null
              ? '✅ Departamento actualizado exitosamente'
              : '✅ Departamento creado exitosamente',
        );
      }
      if (!success) {
        debugPrint('[DepartmentDialog][$mode] Save failed, dialog remains open');
      }
    } catch (e) {
      debugPrint('[DepartmentDialog][$mode] Exception: $e');
      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title:
              'Error al ${widget.department != null ? 'actualizar' : 'crear'} departamento',
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: () => _handleSave(),
        );
      }
      // Manejar el error
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/widgets/local_dialog.dart\n```

import 'package:flutter/material.dart';
import '../models/local.dart';
import '../utils/dialog_error_handler.dart';
import '../utils/validators.dart';

class LocalDialog extends StatefulWidget {
  final Local? local;
  final Function(Local) onSave;

  const LocalDialog({super.key, this.local, required this.onSave});

  @override
  LocalDialogState createState() => LocalDialogState();
}

class LocalDialogState extends State<LocalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false; // <-- AGREGAR ESTADO DE GUARDADO

  @override
  void initState() {
    super.initState();
    if (widget.local != null) {
      _nameController.text = widget.local!.name;
      _phoneController.text = widget.local!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.local != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit : Icons.business,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(isEditMode ? 'Editar Local' : 'Agregar Local'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del local
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del local *',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Sucursal Central',
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'El nombre del local',
                  minLength: 2,
                  maxLength: 100,
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: +53 55512345',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? 'Guardar' : 'Agregar',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final local = Local(
        id: widget.local?.id ?? 0,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Intentar guardar
      await widget.onSave(local);
      if (mounted) {
        // Si llega aquí, fue exitoso
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.local != null
              ? '✅ Local actualizado exitosamente'
              : '✅ Local creado exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        // Manejar el error
        DialogErrorHandler.showErrorDialog(
          context: context,
          title:
              'Error al ${widget.local != null ? 'actualizar' : 'crear'} local',
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: () => _handleSave(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: lib/widgets/shared/responsive_button.dart\n```
import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import 'responsive_text.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 50,
      tablet: 55,
      desktop: 60,
    );

    final fontSize = ResponsiveUtils.getResponsiveTextSize(context, 16);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor),
                  SizedBox(width: 8),
                  ResponsiveText(
                    text: text,
                    size: fontSize,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              )
            : ResponsiveText(
                text: text,
                size: fontSize,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/widgets/shared/responsive_card.dart\n```
// widgets/responsive_card.dart
import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? color;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding =
        padding ?? ResponsiveUtils.getResponsivePadding(context);

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,
        child: Padding(padding: cardPadding, child: child),
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/widgets/shared/responsive_container.dart\n```
// responsive_container.dart - versión corregida
import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool enableScrolling;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.enableScrolling = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: child,
    );

    return enableScrolling ? SingleChildScrollView(child: content) : content;
  }
}
\n```\n
\n## Archivo: lib/widgets/shared/responsive_text.dart\n```
// widgets/responsive_text.dart
import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const ResponsiveText({
    super.key,
    required this.text,
    required this.size,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveTextSize(context, size),
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
\n```\n
\n## Archivo: lib/widgets/worker_dialog.dart\n```
import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../models/department.dart';
import '../models/local.dart';
import '../providers/department_provider.dart';
import '../providers/local_provider.dart';
import '../utils/validators.dart';
import '../../utils/dialog_error_handler.dart'; // <-- IMPORTAR NUEVO HELPER

class WorkerDialog extends StatefulWidget {
  final Worker? worker;
  final Future<bool> Function(Worker) onSave;
  final DepartmentProvider departmentProvider;
  final LocalProvider localProvider;

  const WorkerDialog({
    super.key,
    this.worker,
    required this.onSave,
    required this.departmentProvider,
    required this.localProvider,
  });

  @override
  WorkerDialogState createState() => WorkerDialogState();
}

class WorkerDialogState extends State<WorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _carnetIDController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fechaCumpleanosController = TextEditingController();

  int? _selectedDepartmentId;
  int? _selectedLocalId;
  bool _isSaving = false; // <-- AGREGAR ESTADO DE GUARDADO

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.name;
      _lastNameController.text = widget.worker!.lastName;
      _carnetIDController.text = widget.worker!.carnetID;
      _phoneController.text = widget.worker!.phone;
      _addressController.text = widget.worker!.address;
      _fechaCumpleanosController.text = widget.worker!.fechaCumpleannos;
      _selectedDepartmentId = widget.worker!.departamentoID;
      _selectedLocalId = widget.worker!.localId;
    }
  }

  // Validación personalizada para carnet de identidad
  String? _validateCarnetID(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmedValue = value.trim();

    // Debe tener exactamente 11 dígitos
    if (trimmedValue.length != 11) {
      return 'El carnet debe tener exactamente 11 dígitos';
    }

    // Solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (!onlyNumbersRegex.hasMatch(trimmedValue)) {
      return 'El carnet solo puede contener números';
    }

    // Validar formato básico (primeros dígitos para provincia)
    final provinceCode = int.tryParse(trimmedValue.substring(0, 2));
    if (provinceCode == null || provinceCode < 1 || provinceCode > 16) {
      return 'Los primeros dígitos no corresponden a una provincia válida';
    }

    return null;
  }

  // Validación para fecha de cumpleaños (YYYY-MM-DD)
  String? _validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }

    final trimmedValue = value.trim();

    // Verificar formato YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(trimmedValue)) {
      return 'Formato inválido. Use YYYY-MM-DD (Ej: 1990-05-15)';
    }

    try {
      final parts = trimmedValue.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (year < 1900 || year > DateTime.now().year) {
        return 'Año inválido (1900-${DateTime.now().year})';
      }

      if (month < 1 || month > 12) {
        return 'Mes inválido (1-12)';
      }

      // Validar días según el mes
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        return 'Día inválido para el mes seleccionado';
      }

      // No permitir fechas futuras
      final birthday = DateTime(year, month, day);
      if (birthday.isAfter(DateTime.now())) {
        return 'La fecha de cumpleaños no puede ser futura';
      }
    } catch (e) {
      debugPrint('[WorkerDialog][VALIDATION] Birthday parse exception: $e');
      return 'Fecha inválida';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final departments = widget.departmentProvider.departments;
    final locals = widget.localProvider.locals;
    final isEditMode = widget.worker != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit : Icons.person_add,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isEditMode ? 'Editar Trabajador' : 'Agregar Trabajador',
              softWrap: true,
              maxLines: 2,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Juan',
                ),
                validator: (value) => Validators.validateName(value, 'Nombre'),
              ),

              const SizedBox(height: 16),

              // Apellido
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Pérez',
                ),
                validator: (value) =>
                    Validators.validateName(value, 'Apellido'),
              ),

              const SizedBox(height: 16),

              // Carnet de Identidad
              TextFormField(
                controller: _carnetIDController,
                decoration: const InputDecoration(
                  labelText: 'Carnet de Identidad *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: '11 dígitos (Ej: 91010112345)',
                ),
                keyboardType: TextInputType.number,
                validator: _validateCarnetID,
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: +53 55598765',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
              ),

              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Calle 123, Ciudad',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Opcional
                  }
                  if (value.length > 200) {
                    return 'La dirección no puede exceder 200 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha de Cumpleaños
              TextFormField(
                controller: _fechaCumpleanosController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Cumpleaños',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD (Ej: 1990-05-15)',
                ),
                validator: _validateBirthday,
              ),

              const SizedBox(height: 16),

              // Selector de Departamento
              if (departments.isNotEmpty)
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue:
                      departments.any((d) => d.id == _selectedDepartmentId)
                      ? _selectedDepartmentId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Departamento (opcional)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    hintText: 'Seleccione un departamento',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin departamento'),
                    ),
                    ...departments.map((dept) {
                      return DropdownMenuItem<int?>(
                        value: dept.id,
                        child: Text(dept.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedDepartmentId = newValue;
                    });
                  },
                ),

              const SizedBox(height: 16),

              // Selector de Local
              if (locals.isNotEmpty)
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: locals.any((l) => l.id == _selectedLocalId)
                      ? _selectedLocalId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Local (opcional)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    hintText: 'Seleccione un local',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin local'),
                    ),
                    ...locals.map((local) {
                      return DropdownMenuItem<int?>(
                        value: local.id,
                        child: Text(
                          local.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedLocalId = newValue;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? 'Guardar Cambios' : 'Agregar',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    final mode = widget.worker != null ? 'EDIT' : 'CREATE';
    debugPrint('[WorkerDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[WorkerDialog][$mode] Validation failed');
      return;
    }

    try {
      setState(() => _isSaving = true);
      debugPrint('[WorkerDialog][$mode] Validation passed');
      debugPrint(
        '[WorkerDialog][$mode] Selected departmentId=$_selectedDepartmentId localId=$_selectedLocalId',
      );

      // Obtener objetos completos si existen
      final Department? department = _selectedDepartmentId != null
          ? await widget.departmentProvider.getDepartmentById(
              _selectedDepartmentId!,
            )
          : null;

      final Local? local = _selectedLocalId != null
          ? await widget.localProvider.getLocalById(_selectedLocalId!)
          : null;

      // Crear el Worker con los objetos completos
      final worker = Worker(
        id: widget.worker?.id ?? 0,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        carnetID: _carnetIDController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        fechaCumpleannos: _fechaCumpleanosController.text.trim(),
        department: department,
        local: local,
        cumpleannoId: null,
      );

      debugPrint('[WorkerDialog][$mode] Worker built: ${worker.toJson()}');
      debugPrint('[WorkerDialog][$mode] DTO: ${worker.toCreateDto()}');

      // Intentar guardar
      final success = await widget.onSave(worker);
      debugPrint('[WorkerDialog][$mode] onSave returned success=$success');

      if (success && mounted) {
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.worker != null
              ? '✅ Trabajador actualizado exitosamente'
              : '✅ Trabajador creado exitosamente',
        );
      }

      if (!success) {
        debugPrint('[WorkerDialog][$mode] Save failed, dialog remains open');
      }

      // Si llega aquí, fue exitoso
    } catch (e) {
      // Manejar errores específicos de trabajadores
      debugPrint('[WorkerDialog][$mode] Exception: $e');
      String errorTitle =
          'Error al ${widget.worker != null ? 'actualizar' : 'crear'} trabajador';
      // String friendlyError = _getWorkerSpecificErrorMessage(e.toString());
      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title: errorTitle,
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: () => _handleSave(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // String _getWorkerSpecificErrorMessage(String technicalError) {
  //   final error = technicalError.toLowerCase();

  //   if (error.contains('carnet') && error.contains('duplicad')) {
  //     return '⚠️ El número de carnet ya está registrado. Use uno diferente.';
  //   }

  //   if (error.contains('phone') && error.contains('duplicad')) {
  //     return '📱 El número de teléfono ya está registrado.';
  //   }

  //   if (error.contains('email') && error.contains('duplicad')) {
  //     return '📧 El correo electrónico ya está registrado.';
  //   }

  //   if (error.contains('birthday') || error.contains('cumpleaños') || error.contains('fecha')) {
  //     return '📅 La fecha de cumpleaños no es válida.';
  //   }

  //   return DialogErrorHandler.getFriendlyErrorMessage(technicalError);
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _carnetIDController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _fechaCumpleanosController.dispose();
    super.dispose();
  }
}
\n```\n
\n## Archivo: pubspec.yaml\n```
name: phonebook
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: "none" # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.10.8

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  table_calendar: ^3.2.0
  http: ^1.6.0
  intl: ^0.20.2
  provider: ^6.1.5+1
  permission_handler: ^12.0.1
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.4
  url_launcher: ^6.3.2
  sqflite: ^2.4.2
  path: ^1.9.1
  connectivity_plus: ^7.0.0
  internet_connection_checker: ^1.0.0+1
  path_provider: ^2.1.5
  package_info_plus: ^9.0.0
  flutter_downloader: ^1.12.0
  flutter_local_notifications: ^19.5.0
  android_intent_plus: ^6.0.0
  file_picker: ^11.0.2
  excel: ^4.0.6
  spreadsheet_decoder: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec
# The following section is specific to Flutter packages.
flutter:
  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true
  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg
  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images
  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package
  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package
flutter_intl:
  enabled: true
\n```\n
