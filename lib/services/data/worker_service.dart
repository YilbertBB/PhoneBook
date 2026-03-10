import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/worker.dart';
import '../../utils/error_messages.dart';

class WorkerService {
  final ApiClient _client;

  WorkerService(this._client);

  Future<ApiResponse<List<Worker>>> getWorkers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.workers,
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
        final workers = response.data!
            .map((json) => Worker.fromJson(json))
            .toList();
        return ApiResponse.success(workers);
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

  Future<ApiResponse<Worker>> getWorkerById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar específicamente 404
        if (response.statusCode == 404) {
          return ApiResponse.error(
            ErrorMessages.dataNotFound,
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
        final worker = Worker.fromJson(response.data!);
        return ApiResponse.success(worker);
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

  Future<ApiResponse<Worker>> createWorker(Worker worker) async {
    try {
      final dto = worker.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.workers,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('carnet') ?? false) {
              errorMessage =
                  'El número de carnet ya existe. Por favor, use uno diferente.';
            } else if (response.technicalError?.contains('phone') ?? false) {
              errorMessage = 'El número de teléfono ya está registrado.';
            } else if (response.technicalError?.contains('email') ?? false) {
              errorMessage = 'El correo electrónico ya está registrado.';
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
        final newWorker = Worker.fromJson(response.data!);

        return ApiResponse.success(newWorker);
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

  Future<ApiResponse<Worker>> updateWorker(Worker worker) async {
    try {
      final dto = worker.toUpdateDto();

      if (worker.id <= 0) {
        return ApiResponse.error(
          'ID de trabajador inválido para actualización',
          technicalError: 'Invalid worker ID: ${worker.id}',
        );
      }

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.workerById(worker.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El trabajador no existe o ha sido eliminado',
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
        final updatedWorker = Worker.fromJson(response.data!);

        return ApiResponse.success(updatedWorker);
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

  Future<ApiResponse<bool>> deleteWorker(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.workerById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        // Manejar específicamente 404
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El trabajador ya ha sido eliminado',
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

  Future<ApiResponse<List<Worker>>> searchWorkers(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workerSearch}$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.operationFailed,
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
          ErrorMessages.dataProcessingError,
          technicalError: 'Parse Error: $e',
        );
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Worker>>> getBirthdayWorkers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Si falla, devolver lista vacía sin mostrar error al usuario
        // (esto es opcional, depende de tus requerimientos)
        return ApiResponse.success([]);
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
        return ApiResponse.success([]); // Silencioso para cumpleaños
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }

  Future<ApiResponse<List<Worker>>> getTodayBirthdays() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.workers}/cumpleannos/hoy',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]); // Silencioso para cumpleaños
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
        return ApiResponse.success([]); // Silencioso para cumpleaños
      }
    } catch (e) {
      return ApiResponse.success([]); // Silencioso para cumpleaños
    }
  }
}
