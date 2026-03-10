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
