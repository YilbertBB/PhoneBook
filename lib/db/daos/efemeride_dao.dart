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
}