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
