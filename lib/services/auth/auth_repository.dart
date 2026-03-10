import 'package:flutter/widgets.dart';

import '../../db/app_database.dart';
import '../../db/daos/user_dao.dart';
import '../../db/entities/user_entity.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../../models/user.dart';
import 'auth_service.dart';
import 'token_manager.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  final TokenManager _tokenManager;
  final AuthService _authService;
  late UserDao _userDao;

  AuthRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
    required TokenManager tokenManager,
    required AuthService authService,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager,
       _tokenManager = tokenManager,
       _authService = authService {
    _userDao = appDatabase.userDao;
  }

  // ========== MÉTODOS PRINCIPALES ==========

  // ✅ OFFLINE: Verificar si hay sesión guardada
  Future<User?> getCachedUser() async {
    try {
      // 1. Verificar si hay sesión válida en la BD
      final hasValidSession = await _userDao.hasValidSession();
      if (!hasValidSession) return null;

      // 2. Obtener el usuario de la sesión
      final session = await _userDao.getSession();
      if (session == null) return null;

      // 3. Obtener información del usuario desde la BD
      final userEntity = await _userDao.getUserById(session.userId);
      if (userEntity == null) return null;

      return _userDao.toUserModel(userEntity);
    } catch (e) {
      return null;
    }
  }

  // ✅ OFFLINE: Verificar si el token es válido localmente
  Future<bool> isTokenValidLocally() async {
    try {
      // 1. Verificar si hay token en el manager
      final token = await _tokenManager.getToken();
      if (token == null) return false;

      // 2. Verificar si hay sesión en la BD
      final hasValidSession = await _userDao.hasValidSession();
      if (!hasValidSession) return false;

      // 3. Verificar expiración del token JWT (simplificado)
      final session = await _userDao.getSession();
      return session != null && session.isValid;
    } catch (e) {
      return false;
    }
  }

  // ❌ SOLO ONLINE: Login real (necesita conexión)
  Future<ApiResponse<User>> loginOnline(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      // Verificar conexión
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para iniciar sesión');
      }

      // Usar el AuthService existente para el login online
      final response = await _authService.login(usernameOrEmail, password);

      if (!response.hasError && response.data != null) {
        // Guardar sesión localmente
        await _saveSessionLocally(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Guardar sesión localmente
  Future<void> _saveSessionLocally(User user) async {
    try {
      // 1. Guardar usuario en la BD
      final userEntity = UserEntity.fromUserModel(user);
      await _userDao.insertOrUpdateUser(userEntity);

      // 2. Obtener token del manager
      final token = await _tokenManager.getToken();
      final refreshToken = await _tokenManager.getRefreshToken();

      if (token != null) {
        // 3. Calcular expiración (asumir 24 horas por defecto)
        final expiresAt = DateTime.now().add(Duration(hours: 24));

        // 4. Guardar sesión en la BD
        final session = SessionEntity(
          userId: user.id,
          token: token,
          refreshToken: refreshToken ?? token,
          expiresAt: expiresAt,
          loggedInAt: DateTime.now(),
        );

        await _userDao.saveSession(session);
      }
    } catch (e) {
      debugPrint('Error guardando sesión localmente: $e');
    }
  }

  // ❌ SOLO ONLINE: Logout
  Future<ApiResponse<bool>> logoutOnline() async {
    try {
      // 1. Verificar conexión (opcional, pero buena práctica)
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        // Aún así podemos limpiar la sesión local
        await _clearLocalSession();
        return ApiResponse.success(true);
      }

      // 2. Usar el AuthService para logout en backend
      final response = await _authService.logout();

      // 3. Limpiar sesión local independientemente del resultado
      await _clearLocalSession();

      return response;
    } catch (e) {
      // En caso de error, igual limpiar sesión local
      await _clearLocalSession();
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Limpiar sesión local
  Future<void> _clearLocalSession() async {
    try {
      // 1. Limpiar tokens
      await _tokenManager.deleteToken();
      _apiClient.updateToken(null);

      // 2. Limpiar sesión de la BD
      await _userDao.clearSession();

      // NOTA: No eliminamos los usuarios de la BD
      // para mantener el cache de usuarios
    } catch (e) {
      debugPrint('Error limpiando sesión local: $e');
    }
  }

  // ✅ OFFLINE: Obtener usuario actual (desde cache)
  Future<User?> getCurrentUserOffline() async {
    return await getCachedUser();
  }

  // 🔄 Obtener usuario actual (intenta online, fallback a offline)
  Future<ApiResponse<User>> getCurrentUser({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          // Intentar obtener del backend
          final response = await _authService.getCurrentUser();

          if (!response.hasError && response.data != null) {
            // Guardar en cache
            await _saveSessionLocally(response.data!);
            return response;
          }
        } catch (e) {
          debugPrint('Error obteniendo usuario desde API: $e');
        }
      }

      // Fallback a datos locales
      final cachedUser = await getCachedUser();
      if (cachedUser != null) {
        return ApiResponse.success(cachedUser);
      }

      return ApiResponse.error('No hay usuario autenticado');
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // ✅ OFFLINE: Verificar permisos básicos
  Future<bool> hasPermissionOffline(String permission) async {
    try {
      final user = await getCachedUser();
      if (user == null) return false;

      // Verificaciones simples basadas en roles
      switch (permission) {
        case 'admin':
          return user.isAdmin;
        case 'view_users':
          return user.isAdmin || user.isConsult;
        case 'edit_users':
          return user.isAdmin;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final hasSession = await _userDao.hasValidSession();
      final session = await _userDao.getSession();
      final user = await getCachedUser();

      return {
        'hasSession': hasSession,
        'userId': user?.id ?? 0,
        'username': user?.username ?? 'No autenticado',
        'isAdmin': user?.isAdmin ?? false,
        'sessionValid': session?.isValid ?? false,
        'expiresIn': session?.timeUntilExpiry.toString() ?? 'N/A',
      };
    } catch (e) {
      return {'hasSession': false, 'error': e.toString()};
    }
  }

  // Validar token con renovación automática
  Future<bool> validateTokenWithRefresh() async {
    try {
      // 1. Verificar localmente primero
      final isValidLocally = await isTokenValidLocally();
      if (!isValidLocally) return false;

      // 2. Si hay conexión, intentar validar con backend
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final response = await _authService.validateToken();
        if (response.hasError) {
          // Intentar refrescar token
          final refreshResponse = await _authService.refreshAccessToken();
          return !refreshResponse.hasError;
        }
        return true;
      }

      // 3. Sin conexión, confiar en validación local
      return isValidLocally;
    } catch (e) {
      return false;
    }
  }
}
