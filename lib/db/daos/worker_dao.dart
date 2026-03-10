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
        'local_id',
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
        'local_id',
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
