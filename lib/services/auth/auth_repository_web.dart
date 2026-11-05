// lib/services/auth/auth_repository_web.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../utils/connectivity_manager.dart';
import 'auth_service.dart';
import 'token_manager.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  final TokenManager _tokenManager;
  final AuthService _authService;

  AuthRepository({
    required ApiClient apiClient,
    required ConnectivityManager connectivityManager,
    required TokenManager tokenManager,
    required AuthService authService,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager,
       _tokenManager = tokenManager,
       _authService = authService;

  // ========== SESIÓN (solo token + prefs en web) ==========

  Future<User?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user');
      if (raw == null) return null;
      return User.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isTokenValidLocally() async {
    final token = await _tokenManager.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<ApiResponse<User>> loginOnline(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (!hasNetwork) {
        return ApiResponse.error('Se requiere conexión para iniciar sesión');
      }
      final response = await _authService.login(usernameOrEmail, password);
      if (!response.hasError && response.data != null) {
        await _saveUserToPrefs(response.data!);
      }
      return response;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> logoutOnline() async {
    try {
      final response = await _authService.logout();
      await _clearLocalSession();
      return response;
    } catch (e) {
      await _clearLocalSession();
      return ApiResponse.fromException(e);
    }
  }

  Future<void> _clearLocalSession() async {
    await _tokenManager.deleteToken();
    _apiClient.updateToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  Future<User?> getCurrentUserOffline() async => getCachedUser();

  Future<ApiResponse<User>> getCurrentUser({bool forceRefresh = false}) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final response = await _authService.getCurrentUser();
        if (!response.hasError && response.data != null) {
          await _saveUserToPrefs(response.data!);
          return response;
        }
      }
      final cached = await getCachedUser();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error('No hay usuario autenticado');
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<bool> hasPermissionOffline(String permission) async {
    final user = await getCachedUser();
    if (user == null) return false;
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
  }

  Future<Map<String, dynamic>> getSessionStats() async {
    final user = await getCachedUser();
    final token = await _tokenManager.getToken();
    return {
      'hasSession': token != null && token.isNotEmpty,
      'userId': user?.id ?? 0,
      'username': user?.username ?? 'No autenticado',
      'isAdmin': user?.isAdmin ?? false,
      'sessionValid': token != null && token.isNotEmpty,
      'expiresIn': 'N/A',
    };
  }

  Future<bool> validateTokenWithRefresh() async {
    final isValidLocally = await isTokenValidLocally();
    if (!isValidLocally) return false;
    final hasNetwork = await _connectivityManager.hasNetworkConnection();
    if (hasNetwork) {
      final response = await _authService.validateToken();
      if (response.hasError) {
        final refresh = await _authService.refreshAccessToken();
        return !refresh.hasError;
      }
      return true;
    }
    return isValidLocally;
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', json.encode(user.toJson()));
    } catch (e) {
      debugPrint('Error guardando usuario en prefs: $e');
    }
  }
}

AuthRepository createAuthRepository({
  required dynamic apiClient,
  dynamic appDatabase,
  required dynamic connectivityManager,
  required dynamic tokenManager,
  required dynamic authService,
}) {
  return AuthRepository(
    apiClient: apiClient,
    connectivityManager: connectivityManager,
    tokenManager: tokenManager,
    authService: authService,
  );
}
