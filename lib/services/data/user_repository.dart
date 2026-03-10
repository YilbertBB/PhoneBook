import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/user_dao.dart';
import '../../db/entities/user_entity.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/create_usuario_dto.dart';
import 'user_service.dart';

class UserRepository {
  final ConnectivityManager _connectivityManager;
  final UserService _userService;
  late UserDao _userDao;

  UserRepository({
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
    required UserService userService,
  }) : _connectivityManager = connectivityManager,
       _userService = userService {
    _userDao = appDatabase.userDao;
  }

  // ========== MÉTODOS DE LECTURA (OFFLINE) ==========

  // ✅ OFFLINE: Obtener usuarios desde cache local
  Future<ApiResponse<List<User>>> getUsersLocal() async {
    try {
      final entities = await _userDao.getAllUsers();
      final users = _userDao.toUserModelList(entities);
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Error al obtener usuarios locales');
    }
  }

  // ✅ OFFLINE: Obtener usuario por ID desde cache
  Future<ApiResponse<User?>> getUserByIdLocal(int id) async {
    try {
      final entity = await _userDao.getUserById(id);
      if (entity == null) {
        return ApiResponse.success(null);
      }
      final user = _userDao.toUserModel(entity);
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.error('Error al obtener usuario local');
    }
  }

  // ✅ OFFLINE: Buscar usuarios localmente
  Future<ApiResponse<List<User>>> searchUsersLocal(String query) async {
    try {
      final entities = await _userDao.searchUsers(query);
      final users = _userDao.toUserModelList(entities);
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Error al buscar usuarios localmente');
    }
  }

  // ========== MÉTODOS CON SINCRONIZACIÓN ==========

  // 🔄 Obtener usuarios (offline-first con sincronización)
  Future<ApiResponse<List<User>>> getUsers({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      // Si hay red y se fuerza refresco, obtener de API
      if (hasNetwork && forceRefresh) {
        try {
          final apiResponse = await _getUsersFromApi();
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveUsersToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      // Fallback a datos locales
      return await getUsersLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // 🔄 Buscar usuarios (intenta online, fallback a offline)
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      // Primero buscar localmente
      final localResponse = await searchUsersLocal(query);
      final localUsers = localResponse.data ?? [];

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _searchUsersInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            // Guardar nuevos usuarios encontrados
            await _saveUsersToLocal(apiResponse.data!);

            // Combinar resultados
            final combined = _mergeUserLists(localUsers, apiResponse.data!);
            return ApiResponse.success(combined);
          }
        } catch (e) {
          debugPrint('⚠️ API de búsqueda falló: $e');
        }
      }

      return ApiResponse.success(localUsers);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== MÉTODOS DE ESCRITURA (SOLO ONLINE) ==========

  // ❌ SOLO ONLINE: Crear usuario
  Future<ApiResponse<User>> createUserOnline(
    CreateUsuarioDto usuarioDto,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para crear usuarios');
      }

      final response = await _userService.createUser(usuarioDto);

      if (!response.hasError && response.data != null) {
        // Guardar el nuevo usuario localmente
        await _saveUserToLocal(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ❌ SOLO ONLINE: Actualizar usuario
  Future<ApiResponse<User>> updateUserOnline(User user) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error(
          'Se requiere conexión para actualizar usuarios',
        );
      }

      final response = await _userService.updateUser(user);

      if (!response.hasError && response.data != null) {
        // Actualizar usuario localmente
        await _saveUserToLocal(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ❌ SOLO ONLINE: Eliminar usuario
  // Future<ApiResponse<bool>> deleteUserOnline(int id) async {
  //   try {
  //     final hasNetwork = await _connectivityManager.hasNetworkConnection();
  //     if (!hasNetwork) {
  //       return ApiResponse.error('Se requiere conexión para eliminar usuarios');
  //     }

  //     final response = await _userService.deleteUser(id);

  //     if (!response.hasError && response.data == true) {
  //       // Eliminar usuario localmente
  //       await _userDao.deleteUser(id);
  //     }

  //     return response;
  //   } catch (e) {
  //     return ApiResponse.fromException(e);
  //   }
  // }

  // ❌ SOLO ONLINE: Actualizar roles
  Future<ApiResponse<User>> updateUserRolesOnline(
    int userId,
    List<int> roleIds,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para actualizar roles');
      }

      return await _userService.updateUserRoles(userId, roleIds);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ========== SINCRONIZACIÓN ==========

  // 🔄 Sincronizar usuarios con el backend
  Future<bool> syncUsers() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) return false;

      final apiResponse = await _getUsersFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveUsersToLocal(apiResponse.data!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  Future<ApiResponse<List<User>>> _getUsersFromApi() async {
    try {
      final response = await _userService.getUsers();
      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<User>>> _searchUsersInApi(String query) async {
    try {
      final response = await _userService.searchUsers(query);
      return response;
    } catch (e) {
      return ApiResponse.success([]);
    }
  }

  Future<void> _saveUsersToLocal(List<User> users) async {
    try {
      final entities = users
          .map((user) => UserEntity.fromUserModel(user))
          .toList();
      await _userDao.insertOrUpdateUsers(entities);
    } catch (e) {
      debugPrint('Error al guardar usuarios en local: $e');
    }
  }

  Future<void> _saveUserToLocal(User user) async {
    try {
      final entity = UserEntity.fromUserModel(user);
      await _userDao.insertOrUpdateUser(entity);
    } catch (e) {
      debugPrint('Error al guardar usuario en local: $e');
    }
  }

  List<User> _mergeUserLists(List<User> list1, List<User> list2) {
    final Map<int, User> mergedMap = {};
    for (final user in list1) {
      mergedMap[user.id] = user;
    }
    for (final user in list2) {
      mergedMap[user.id] = user;
    }
    return mergedMap.values.toList();
  }

  // ========== ESTADÍSTICAS ==========

  Future<Map<String, dynamic>> getLocalStats() async {
    try {
      final stats = await _userDao.getStats();
      return stats;
    } catch (e) {
      return {
        'totalUsers': 0,
        'lastSyncFormatted': 'Nunca',
        'hasSession': false,
      };
    }
  }

  // Obtener estadísticas (intenta online, fallback a offline)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        final response = await _userService.getUserStats();
        if (!response.hasError && response.data != null) {
          return response.data!;
        }
      }

      // Fallback a estadísticas locales
      final localStats = await getLocalStats();
      return {
        'total': localStats['totalUsers'] ?? 0,
        'admin': localStats['adminCount'] ?? 0,
        'consult':
            (localStats['totalUsers'] ?? 0) - (localStats['adminCount'] ?? 0),
        'activos': localStats['totalUsers'] ?? 0,
        'inactivos': 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'admin': 0,
        'consult': 0,
        'activos': 0,
        'inactivos': 0,
      };
    }
  }
}
