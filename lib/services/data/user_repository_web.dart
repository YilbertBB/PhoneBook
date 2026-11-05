// lib/services/data/user_repository_web.dart
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/create_usuario_dto.dart';
import 'user_service.dart';

class UserRepository {
  final UserService _userService;

  UserRepository({required UserService userService})
    : _userService = userService;

  // ========== LECTURA ==========

  Future<ApiResponse<List<User>>> getUsers({bool forceRefresh = false}) async {
    return await _userService.getUsers();
  }

  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    return await _userService.searchUsers(query);
  }

  // Stubs neutros: en web no hay cache local de usuarios
  Future<ApiResponse<List<User>>> getUsersLocal() async =>
      ApiResponse.success([]);

  Future<ApiResponse<User?>> getUserByIdLocal(int id) async =>
      ApiResponse.success(null);

  Future<ApiResponse<List<User>>> searchUsersLocal(String query) async =>
      ApiResponse.success([]);

  // ========== ESCRITURA ==========

  Future<ApiResponse<User>> createUserOnline(
    CreateUsuarioDto usuarioDto,
  ) async {
    return await _userService.createUser(usuarioDto);
  }

  Future<ApiResponse<User>> updateUserOnline(User user) async {
    return await _userService.updateUser(user);
  }

  Future<ApiResponse<User>> updateUserRolesOnline(
    int userId,
    List<int> roleIds,
  ) async {
    return await _userService.updateUserRoles(userId, roleIds);
  }

  // ========== SINCRONIZACIÓN ==========

  Future<bool> syncUsers() async => false;

  // ========== ESTADÍSTICAS ==========

  Future<Map<String, dynamic>> getLocalStats() async => {
    'totalUsers': 0,
    'lastSyncFormatted': 'No aplica en web',
    'hasSession': false,
  };

  Future<Map<String, dynamic>> getUserStats() async {
    final response = await _userService.getUserStats();
    if (response.hasError || response.data == null) {
      return {
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      };
    }
    return response.data!;
  }
}

// Factory FUERA de la clase
UserRepository createUserRepository({
  dynamic appDatabase,
  dynamic connectivityManager,
  required dynamic userService,
}) {
  return UserRepository(userService: userService);
}
