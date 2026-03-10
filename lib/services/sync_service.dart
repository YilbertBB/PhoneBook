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
