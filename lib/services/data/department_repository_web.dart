// lib/services/data/department_repository_web.dart
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/department.dart';
import '../../models/department_lite.dart';

class DepartmentRepository {
  final ApiClient _apiClient;

  DepartmentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ========== MÉTODOS PRINCIPALES ==========

  Future<ApiResponse<List<Department>>> getDepartments({
    bool forceRefresh = false,
  }) async {
    return await _getDepartmentsFromApi();
  }

  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.departments}/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Departamento no encontrado',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Department.fromJson(response.data!));
  }

  Future<ApiResponse<Department>> createDepartment(Department d) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.departments,
      body: d.toCreateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al crear departamento',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Department.fromJson(response.data!));
  }

  Future<ApiResponse<Department>> updateDepartment(Department d) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.departments}/${d.id}',
      body: d.toUpdateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al actualizar departamento',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Department.fromJson(response.data!));
  }

  Future<ApiResponse<bool>> deleteDepartment(int id) async {
    final response = await _apiClient.delete<bool>(
      '${ApiEndpoints.departments}/$id',
      fromJson: (json) => true,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al eliminar departamento',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(true);
  }

  Future<ApiResponse<List<Department>>> searchDepartments(String query) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.departments}/search/$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Department.fromJson(j)).toList(),
    );
  }

  // ========== MÉTODOS USADOS POR EL PROVIDER (stubs neutros) ==========
  // En web no hay datos locales; devolvemos valores vacíos para que el
  // provider no falle.

  Future<Map<String, dynamic>> getLocalStats() async => {
    'totalDepartments': 0,
    'lastSyncDate': null,
    'lastSyncFormatted': 'No aplica en web',
  };

  Future<bool> syncDepartments() async => false;

  Future<List<Department>> getLocalDepartmentsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async => [];

  Future<List<DepartmentLite>> getLocalDepartmentsLitePaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async => [];

  Future<List<Department>> searchDepartmentsPaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async => [];

  Future<List<DepartmentLite>> searchDepartmentsLitePaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    // En web sí podemos buscar en API y convertir el resultado
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.departments}/search/$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return [];
    }

    return response.data!
        .map((j) => DepartmentLite.fromDepartment(Department.fromJson(j)))
        .toList();
  }

  Future<int> countDepartmentsWithFilter(String? searchQuery) async => 0;

  // ========== MÉTODO PRIVADO ==========

  Future<ApiResponse<List<Department>>> _getDepartmentsFromApi() async {
    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.departments,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al obtener departamentos',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    if (response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Department.fromJson(j)).toList(),
    );
  }
}

// Factory FUERA de la clase
DepartmentRepository createDepartmentRepository({
  required dynamic apiClient,
  dynamic appDatabase,
  required dynamic connectivityManager,
}) {
  return DepartmentRepository(apiClient: apiClient);
}
