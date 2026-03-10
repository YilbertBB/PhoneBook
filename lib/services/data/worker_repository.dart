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
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (!hasConnection) {
        return ApiResponse.error(
          'No hay conexión a internet. No se puede crear el trabajador.',
          technicalError: 'No connection available for create operation',
        );
      }

      // Crear en API
      final apiResponse = await _createWorkerInApi(worker);

      if (!apiResponse.hasError && apiResponse.data != null) {
        // Guardar en local si se creó exitosamente
        await _saveWorkerToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar trabajador
  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    try {
      final hasConnection = await _connectivityManager.hasNetworkConnection();

      if (!hasConnection) {
        return ApiResponse.error(
          'No hay conexión a internet. Los cambios se guardarán localmente y se sincronizarán después.',
          technicalError: 'No connection for update, storing locally',
        );
      }

      // Actualizar en API
      final apiResponse = await _updateWorkerInApi(worker);

      if (!apiResponse.hasError && apiResponse.data != null) {
        // Actualizar en local
        await _saveWorkerToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
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

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.workers,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta del servidor');
      }

      try {
        final newWorker = Worker.fromJson(response.data!);
        return ApiResponse.success(newWorker);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar trabajador creado',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Worker>> _updateWorkerInApi(Worker worker) async {
    try {
      final dto = worker.toUpdateDto();

      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.workerById(worker.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar trabajador',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta del servidor');
      }

      try {
        final updatedWorker = Worker.fromJson(response.data!);
        return ApiResponse.success(updatedWorker);
      } catch (e) {
        return ApiResponse.error(
          'Error al procesar trabajador actualizado',
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
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
}
