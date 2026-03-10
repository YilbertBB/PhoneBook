import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/local.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class LocalService {
  final ApiClient _client;

  LocalService(this._client);

  Future<ApiResponse<List<Local>>> getLocal() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.local,
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
        final local = response.data!
            .map((json) => Local.fromJson(json))
            .toList();
        return ApiResponse.success(local);
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

  Future<ApiResponse<Local>> getLocalById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.localById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local no existe o ha sido eliminado',
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
        final local = Local.fromJson(response.data!);
        return ApiResponse.success(local);
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

  Future<ApiResponse<Local>> createLocal(Local local) async {
    try {
      final dto = local.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.local,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación específicos
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.toLowerCase().contains('name') ??
                false) {
              errorMessage = 'Ya existe un local con ese nombre.';
            } else if (response.technicalError?.toLowerCase().contains(
                  'phone',
                ) ??
                false) {
              errorMessage = 'Ya existe un local con ese teléfono.';
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
        final newLocal = Local.fromJson(response.data!);

        return ApiResponse.success(newLocal);
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

  Future<ApiResponse<Local>> updateLocal(Local local) async {
    try {
      final dto = local.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.localById(local.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local no existe o ha sido eliminado',
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
        final updatedLocal = Local.fromJson(response.data!);

        return ApiResponse.success(updatedLocal);
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

  Future<ApiResponse<bool>> deleteLocal(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.localById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El local ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Verificar si hay relaciones (trabajadores asignados)
        if (response.statusCode == 409 ||
            (response.technicalError?.contains('relación') ?? false) ||
            (response.technicalError?.contains('dependencia') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el local porque tiene trabajadores asignados. '
            'Reasigna los trabajadores primero.',
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
}
