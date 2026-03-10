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
