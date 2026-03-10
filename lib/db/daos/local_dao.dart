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
