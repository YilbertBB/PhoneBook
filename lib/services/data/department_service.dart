import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/department.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class DepartmentService {
  final ApiClient _client;

  DepartmentService(this._client);

  Future<ApiResponse<List<Department>>> getDepartments() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.departments,
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
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
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

  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.departmentById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento no existe o ha sido eliminado',
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
        final department = Department.fromJson(response.data!);
        return ApiResponse.success(department);
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

  Future<ApiResponse<Department>> createDepartment(
    Department department,
  ) async {
    try {
      final dto = department.toCreateDto();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.departments,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores de validación
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.toLowerCase().contains('name') ??
                false) {
              errorMessage = 'Ya existe un departamento con ese nombre.';
            } else if (response.technicalError?.toLowerCase().contains(
                  'phone',
                ) ??
                false) {
              errorMessage = 'Ya existe un departamento con ese teléfono.';
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
        final newDepartment = Department.fromJson(response.data!);

        return ApiResponse.success(newDepartment);
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

  Future<ApiResponse<Department>> updateDepartment(
    Department department,
  ) async {
    try {
      final dto = department.toUpdateDto();

      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.departmentById(department.id),
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento no existe o ha sido eliminado',
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
        final updatedDepartment = Department.fromJson(response.data!);

        return ApiResponse.success(updatedDepartment);
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

  Future<ApiResponse<bool>> deleteDepartment(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.departmentById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El departamento ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Verificar si hay relaciones (trabajadores asignados)
        if (response.statusCode == 409 ||
            (response.technicalError?.contains('relación') ?? false) ||
            (response.technicalError?.contains('dependencia') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el departamento porque tiene trabajadores asignados. '
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
