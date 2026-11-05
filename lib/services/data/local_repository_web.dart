// lib/services/data/local_repository_web.dart
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/local.dart';
import '../../models/local_lite.dart';

class LocalRepository {
  final ApiClient _apiClient;

  LocalRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ========== MÉTODOS PRINCIPALES ==========

  Future<ApiResponse<List<Local>>> getLocals({
    bool forceRefresh = false,
  }) async {
    return await _getLocalsFromApi();
  }

  Future<ApiResponse<Local>> getLocalById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.local}/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Local no encontrado',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Local.fromJson(response.data!));
  }

  Future<ApiResponse<Local>> createLocal(Local local) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.local,
      body: local.toCreateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al crear local',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Local.fromJson(response.data!));
  }

  Future<ApiResponse<Local>> updateLocal(Local local) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.local}/${local.id}',
      body: local.toUpdateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al actualizar local',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Local.fromJson(response.data!));
  }

  Future<ApiResponse<bool>> deleteLocal(int id) async {
    final response = await _apiClient.delete<bool>(
      '${ApiEndpoints.local}/$id',
      fromJson: (json) => true,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al eliminar local',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(true);
  }

  Future<ApiResponse<List<Local>>> searchLocals(String query) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.local}/search/$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Local.fromJson(j)).toList(),
    );
  }

  // ========== STUBS NEUTROS (no aplican en web) ==========

  Future<Map<String, dynamic>> getLocalStats() async => {
    'totalLocals': 0,
    'lastSyncDate': null,
    'lastSyncFormatted': 'No aplica en web',
  };

  Future<bool> syncLocals() async => false;

  Future<List<Local>> getLocalLocalsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async => [];

  Future<List<LocalLite>> getLocalLocalsLitePaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async => [];

  Future<List<Local>> searchLocalsPaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async => [];

  Future<List<LocalLite>> searchLocalsLitePaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.local}/search/$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return [];
    }

    return response.data!
        .map((j) => LocalLite.fromLocal(Local.fromJson(j)))
        .toList();
  }

  Future<int> countLocalsWithFilter(String? searchQuery) async => 0;

  // ========== MÉTODO PRIVADO ==========

  Future<ApiResponse<List<Local>>> _getLocalsFromApi() async {
    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.local,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al obtener locales',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    if (response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Local.fromJson(j)).toList(),
    );
  }
}

// Factory FUERA de la clase
LocalRepository createLocalRepository({
  required dynamic apiClient,
  dynamic appDatabase,
  required dynamic connectivityManager,
}) {
  return LocalRepository(apiClient: apiClient);
}
