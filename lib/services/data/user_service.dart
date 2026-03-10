import '../../models/create_usuario_dto.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/rol.dart';
import '../../utils/error_messages.dart'; // <-- IMPORTAR

class UserService {
  final ApiClient _client;

  UserService(this._client);

  // ========== USER METHODS ==========

  Future<ApiResponse<List<User>>> getUsers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.users,
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
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
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

  Future<ApiResponse<User>> getUserById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.userById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
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
        final user = User.fromJson(response.data!);
        return ApiResponse.success(user);
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

  Future<ApiResponse<User>> createUser(CreateUsuarioDto usuarioDto) async {
    try {
      final requestBody = usuarioDto.toJson();

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos
        if (response.statusCode == 400) {
          String errorMessage = ErrorMessages.validationError;
          try {
            if (response.technicalError?.contains('nombreUsuario') ?? false) {
              errorMessage = 'El nombre de usuario ya existe.';
            } else if (response.technicalError?.contains('email') ?? false) {
              errorMessage = 'El correo electrónico ya está registrado.';
            } else if (response.technicalError?.contains('password') ?? false) {
              errorMessage =
                  'La contraseña no cumple los requisitos. Debe tener al menos 6 caracteres.';
            }
          } catch (_) {}

          return ApiResponse.error(
            errorMessage,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 409) {
          return ApiResponse.error(
            'El usuario o email ya existen. Por favor, use datos diferentes.',
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
        final user = User.fromJson(response.data!);

        return ApiResponse.success(user);
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

  Future<ApiResponse<User>> updateUser(User user) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.userById(user.id),
        body: user.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
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
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
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

  Future<ApiResponse<bool>> deleteUser(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.userById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario ya ha sido eliminado',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // No permitir eliminar el último administrador
        if (response.statusCode == 403 ||
            (response.technicalError?.contains('administrador') ?? false)) {
          return ApiResponse.error(
            'No se puede eliminar el último administrador del sistema.',
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

  Future<ApiResponse<User>> updateUserRoles(
    int userId,
    List<int> roleIds,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '${ApiEndpoints.userById(userId)}/roles',
        body: {'roleIds': roleIds},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error(
            'El usuario no existe o ha sido eliminado',
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
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
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

  Future<ApiResponse<User>> updateUserPassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '${ApiEndpoints.userById(userId)}/password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 400) {
          return ApiResponse.error(
            'La contraseña actual es incorrecta',
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 422) {
          return ApiResponse.error(
            'La nueva contraseña no cumple los requisitos de seguridad',
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
        final updatedUser = User.fromJson(response.data!);

        return ApiResponse.success(updatedUser);
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

  // ========== ROLE METHODS ==========

  Future<ApiResponse<List<Rol>>> getRoles() async {
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.roles,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para roles, podemos devolver los predeterminados si hay error
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }

      if (response.data == null) {
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }

      try {
        final roles = response.data!.map((json) => Rol.fromJson(json)).toList();
        return ApiResponse.success(roles);
      } catch (e) {
        // Si hay error de parseo, devolver roles predeterminados
        return ApiResponse.success([
          Rol(id: 1, nombre: 'admin'),
          Rol(id: 2, nombre: 'consult'),
        ]);
      }
    } catch (e) {
      return ApiResponse.success([
        Rol(id: 1, nombre: 'admin'),
        Rol(id: 2, nombre: 'consult'),
      ]);
    }
  }

  Future<ApiResponse<Rol>> getRoleById(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.roleById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        if (response.statusCode == 404) {
          return ApiResponse.error('El rol no existe');
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
        final role = Rol.fromJson(response.data!);
        return ApiResponse.success(role);
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

  // ========== SEARCH & FILTER METHODS ==========

  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.users}?search=$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        // Para búsqueda, devolver lista vacía sin error
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  // ========== STATISTICS METHODS ==========

  Future<ApiResponse<Map<String, dynamic>>> getUserStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '${ApiEndpoints.users}/estadisticas',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Para estadísticas, devolver valores por defecto
        return ApiResponse.success({
          'total': 0,
          'admin': 0,
          'consult': 0,
          'activos': 0,
          'inactivos': 0,
        });
      }

      if (response.data == null) {
        return ApiResponse.success({
          'total': 0,
          'admin': 0,
          'consult': 0,
          'activos': 0,
          'inactivos': 0,
        });
      }

      return ApiResponse.success(response.data!);
    } catch (e) {
      return ApiResponse.success({
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      });
    }
  }

  // Métodos restantes simplificados
  Future<ApiResponse<Rol>> createRole(Rol role) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.roles,
        body: role.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      return ApiResponse.success(Rol.fromJson(response.data!));
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Rol>> updateRole(Rol role) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.roleById(role.id),
        body: role.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      return ApiResponse.success(Rol.fromJson(response.data!));
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> deleteRole(int id) async {
    try {
      final response = await _client.delete<bool>(
        ApiEndpoints.roleById(id),
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar rol',
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Rol>>> getUserRoles(int userId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.userById(userId)}/roles',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final roles = response.data!.map((json) => Rol.fromJson(json)).toList();
        return ApiResponse.success(roles);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<ApiResponse<List<User>>> getUsersByRole(String roleName) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '${ApiEndpoints.users}?role=$roleName',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.success([]);
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final users = response.data!
            .map((json) => User.fromJson(json))
            .toList();
        return ApiResponse.success(users);
      } catch (e) {
        return ApiResponse.success([]);
      }
    } catch (e) {
      return ApiResponse.success([]);
    }
  }
}
