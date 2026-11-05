// lib/services/data/efemeride_repository_web.dart
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/efemeride.dart';

class EfemerideRepository {
  final ApiClient _apiClient;

  EfemerideRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ========== CRUD PRINCIPAL ==========

  Future<ApiResponse<List<Efemeride>>> getEfemerides({
    bool forceRefresh = false,
  }) async {
    return await _getEfemeridesFromApi();
  }

  Future<ApiResponse<Efemeride>> getEfemerideById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.efemerides}/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Efeméride no encontrada',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Efemeride.fromJson(response.data!));
  }

  Future<ApiResponse<Efemeride>> createEfemeride(Efemeride e) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.efemerides,
      body: e.toCreateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al crear efeméride',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Efemeride.fromJson(response.data!));
  }

  Future<ApiResponse<Efemeride>> updateEfemeride(Efemeride e) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.efemerides}/${e.id}',
      body: e.toUpdateDto(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.error(
        response.error ?? 'Error al actualizar efeméride',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(Efemeride.fromJson(response.data!));
  }

  Future<ApiResponse<bool>> deleteEfemeride(int id) async {
    final response = await _apiClient.delete<bool>(
      '${ApiEndpoints.efemerides}/$id',
      fromJson: (json) => true,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al eliminar efeméride',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(true);
  }

  // ========== CONSULTAS FILTRADAS ==========

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByMonth(int month) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}/mes/$month',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByDate(
    DateTime date,
  ) async {
    final formatted = date.toIso8601String().split('T')[0];
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}/fecha/$formatted',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Efemeride>>> getTodayEfemerides() async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}/hoy',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Efemeride>>> getUpcomingEfemerides(int days) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}/proximos/$days',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByYear(int year) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}/año/$year',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  Future<ApiResponse<List<Efemeride>>> searchEfemerides(String query) async {
    final response = await _apiClient.get<List<dynamic>>(
      '${ApiEndpoints.efemerides}?search=$query',
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError || response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }

  // ========== STUBS NEUTROS ==========

  Future<bool> syncEfemerides() async => false;

  Future<Map<String, dynamic>> getLocalStats() async => {
    'totalEfemerides': 0,
    'lastSyncDate': null,
    'lastSyncFormatted': 'No aplica en web',
    'currentYear': DateTime.now().year,
    'monthlyStats': {},
    'todayCount': 0,
  };

  Future<Map<String, dynamic>> getEfemerideStats() async {
    // En web sí podemos pedir stats a la API
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.efemerides}/stats',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.hasError || response.data == null) {
      return {
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
        'hoy': 0,
        'last_sync': 'No aplica en web',
        'is_offline': false,
      };
    }
    return response.data!;
  }

  // ========== MÉTODO PRIVADO ==========

  Future<ApiResponse<List<Efemeride>>> _getEfemeridesFromApi() async {
    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.efemerides,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.hasError) {
      return ApiResponse.error(
        response.error ?? 'Error al obtener efemérides',
        technicalError: response.technicalError,
        statusCode: response.statusCode,
      );
    }

    if (response.data == null) {
      return ApiResponse.success([]);
    }

    return ApiResponse.success(
      response.data!.map((j) => Efemeride.fromJson(j)).toList(),
    );
  }
}

// Factory FUERA de la clase
EfemerideRepository createEfemerideRepository({
  required dynamic apiClient,
  dynamic appDatabase,
  required dynamic connectivityManager,
}) {
  return EfemerideRepository(apiClient: apiClient);
}
