// lib/services/data/worker_repository_web.dart
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/worker.dart';
import '../../models/worker_lite.dart';

class WorkerRepository {
  final ApiClient _apiClient;

  WorkerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==================== MÉTODOS PRINCIPALES ====================

  Future<ApiResponse<List<Worker>>> getWorkers({
    bool forceRefresh = false,
  }) async {
    // En web, usar la versión paginada con límite grande para tener todos
    final response = await getWorkersPaged(
      page: 0,
      limit: 1000,
      forceRefresh: forceRefresh,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al obtener trabajadores',
        technicalError: response.technicalError,
      );
    }

    return ApiResponse.success(
      response.data!.map((lite) => lite.toWorker()).toList(),
    );
  }

  Future<ApiResponse<List<WorkerLite>>> getWorkersPaged({
    int page = 0,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
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

    return ApiResponse.success(
      response.data!.map((j) => WorkerLite.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<WorkerLite>>> searchWorkersPaged(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
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

    if (response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => WorkerLite.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.workers}/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Trabajador no encontrado',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Worker.fromJson(response.data!));
  }

  // ==================== CRUD ====================

  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workers,
      body: worker.toCreateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al crear trabajador',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Worker.fromJson(response.data!));
  }

  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.workers}/${worker.id}',
      body: worker.toUpdateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al actualizar trabajador',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Worker.fromJson(response.data!));
  }

  Future<ApiResponse<bool>> deleteWorker(int id) async {
    final response = await _apiClient.delete<bool>(
      '${ApiEndpoints.workers}/$id',
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
  }

  // ==================== BÚSQUEDA Y CUMPLEAÑOS ====================

  Future<ApiResponse<List<Worker>>> searchWorkers(String query) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.workerSearch}$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Worker.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Worker>>> getBirthdayWorkers() async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.workers}/cumpleannos',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Worker.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Worker>>> getTodayBirthdays() async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.workers}/cumpleannos/hoy',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Worker.fromJson(j)).toList(),
    );
  }

  // ==================== SINCRONIZACIÓN Y ESTADÍSTICAS ====================

  Future<bool> syncWorkers() async => false;

  Future<Map<String, dynamic>> getLocalStats() async => {
    'totalWorkers': 0,
    'lastSyncDate': null,
    'lastSyncFormatted': 'No aplica en web',
  };
}

// Factory FUERA de la clase
WorkerRepository createWorkerRepository({
  required dynamic apiClient,
  dynamic appDatabase,
  required dynamic connectivityManager,
}) {
  return WorkerRepository(apiClient: apiClient);
}
