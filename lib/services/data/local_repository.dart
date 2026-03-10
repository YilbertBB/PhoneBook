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
