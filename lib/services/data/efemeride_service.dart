import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/efemeride.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class EfemerideService {
  final ApiClient _client;

  EfemerideService(this._client);

  // ========== BASIC CRUD METHODS ==========

  Future<ApiResponse<List<Efemeride>>> getEfemerides() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.efemerides,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.dataNotFound,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
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
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'JSON Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> getEfemerideById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride no existe o ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataNotFound);
      }

      try {
        final efemeride = Efemeride.fromJson(response.data!);
        return ApiResponse.success(efemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> createEfemeride(Efemeride efemeride) async {
    try {
      final dto = efemeride.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.efemerides,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('fecha') ?? false) {
              errorMessage = 'La fecha de la efeméride no es válida.';
            } else if (response.technicalError?.contains('dato') ?? false) {
              errorMessage = 'El dato de la efeméride es requerido.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final newEfemeride = Efemeride.fromJson(response.data!);

        return ApiResponse.success(newEfemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Efemeride>> updateEfemeride(Efemeride efemeride) async {
    try {
      final dto = efemeride.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.efemerideById(efemeride.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride no existe o ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 400) {
          return ApiResponse.error(
            ErrorMessages.validationError,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      try {
        final updatedEfemeride = Efemeride.fromJson(response.data!);

        return ApiResponse.success(updatedEfemeride);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteEfemeride(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.efemerideById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'La efeméride ya ha sido eliminada',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== FILTERED QUERIES ==========

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByMonth(int month) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}/mes/$month',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para consultas filtradas, devolver lista vacía sin error
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

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByDate(
    DateTime date,
  ) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];

      final response = await _client.get<List<dynamic>>(
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

  Future<ApiResponse<List<Efemeride>>> getTodayEfemerides() async {
    try {
      final response = await _client.get<List<dynamic>>(
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

  Future<ApiResponse<List<Efemeride>>> getUpcomingEfemerides(int days) async {
    try {
      final response = await _client.get<List<dynamic>>(
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

  Future<ApiResponse<List<Efemeride>>> getEfemeridesByYear(int year) async {
    try {
      final response = await _client.get<List<dynamic>>(
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

  // ========== SEARCH METHODS ==========

  Future<ApiResponse<List<Efemeride>>> searchEfemerides(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
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

  Future<ApiResponse<List<Efemeride>>> searchEfemeridesByDato(
    String dato,
  ) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.efemerides}?dato=$dato',
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

  // ========== STATISTICS METHODS ==========

  Future<ApiResponse<Map<String, dynamic>>> getEfemerideStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.efemerides}/estadisticas',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Devolver estadísticas por defecto
        return ApiResponse.success({
          'total': 0,
          'por_mes': {},
          'por_tipo': {},
          'ultimo_mes': 0,
        });
      }

      if (response.data == null) {
        return ApiResponse.success({
          'total': 0,
          'por_mes': {},
          'por_tipo': {},
          'ultimo_mes': 0,
        });
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      return ApiResponse.success({
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
      });
    }
  }

  // ========== BULK OPERATIONS ==========

  Future<ApiResponse<List<Efemeride>>> createMultipleEfemerides(
    List<Efemeride> efemerides,
  ) async {
    try {
      final efemeridesJson = efemerides.map((e) => e.toJson()).toList();
      final response = await _client.post<List<dynamic>>(
        '${ApiEndpoints.efemerides}/multiple',
        body: {'efemerides': efemeridesJson},
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear múltiples efemérides',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final newEfemerides = response.data!
            .map((json) => Efemeride.fromJson(json))
            .toList();

        return ApiResponse.success(newEfemerides);
      } catch (e) {
        return ApiResponse.error(
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteMultipleEfemerides(List<int> ids) async {
    try {
      final response = await _client.post<bool>(
        '${ApiEndpoints.efemerides}/delete-multiple',
        body: {'ids': ids},
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar múltiples efemérides',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Método simplificado para estadísticas mensuales
  Future<ApiResponse<Map<String, dynamic>>> getMonthlyEfemerideStats(
    int year,
  ) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.efemerides}/estadisticas/mensual/$year',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Devolver estadísticas vacías por mes
        final emptyStats = <String, dynamic>{};
        for (int i = 1; i <= 12; i++) {
          emptyStats[i.toString()] = 0;
        }
        return ApiResponse.success(emptyStats);
      }

      if (response.data == null) {
        final emptyStats = <String, dynamic>{};
        for (int i = 1; i <= 12; i++) {
          emptyStats[i.toString()] = 0;
        }
        return ApiResponse.success(emptyStats);
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      final emptyStats = <String, dynamic>{};
      for (int i = 1; i <= 12; i++) {
        emptyStats[i.toString()] = 0;
      }
      return ApiResponse.success(emptyStats);
    }
  }
}
