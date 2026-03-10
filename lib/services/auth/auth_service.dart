import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../models/user.dart';
import '../../models/rol.dart';
import 'token_manager.dart';
import '../../utils/error_messages.dart'; // <-- AÑADIR ESTA IMPORTACIÓN

class AuthService {
  final ApiClient _client;
  final TokenManager _tokenManager;

  AuthService({required ApiClient client, required TokenManager tokenManager})
    : _client = client,
      _tokenManager = tokenManager;

  Future<ApiResponse<Map<String, dynamic>>> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();

      if (refreshToken == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      // USAR EL NUEVO MÉTODO POST CON ApiResponse
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {'token': refreshToken},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? ErrorMessages.unauthorized,
          technicalError: response.technicalError,
        );
      }

      if (response.data == null) {
        return ApiResponse.error(ErrorMessages.unexpectedError);
      }

      final jsonResponse = response.data!;

      if (!jsonResponse.containsKey('token')) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      final newAccessToken = jsonResponse['token'];
      final newRefreshToken = jsonResponse['refreshToken'] ?? refreshToken;

      if (newAccessToken == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      // Guardar nuevos tokens
      await _tokenManager.saveToken(newAccessToken);
      await _tokenManager.saveRefreshToken(newRefreshToken);
      _client.updateToken(newAccessToken);

      return ApiResponse.success({
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      });
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<User>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final sanitizedInput = usernameOrEmail.trim();
      final sanitizedPassword = password.trim();

      final body = {
        'nombreUsuario': sanitizedInput,
        'password': sanitizedPassword,
      };

      // USAR EL NUEVO MÉTODO POST
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        body: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        // Manejar errores específicos de login
        if (response.statusCode == 401) {
          return ApiResponse.error(
            ErrorMessages.invalidCredentials,
            technicalError: response.technicalError,
            statusCode: response.statusCode,
          );
        }

        // Devolver el error ya traducido desde ApiClient
        return ApiResponse.error(
          response.error ?? ErrorMessages.unexpectedError,
          technicalError: response.technicalError,
          statusCode: response.statusCode,
        );
      }

      final jsonResponse = response.data!;

      final token = jsonResponse['token'];

      if (token == null) {
        return ApiResponse.error(ErrorMessages.dataProcessingError);
      }

      // Guardar token
      await _tokenManager.saveToken(token);
      _client.updateToken(token);

      // Guardar refresh token si viene
      if (jsonResponse.containsKey('refreshToken')) {
        await _tokenManager.saveRefreshToken(jsonResponse['refreshToken']);
      }

      // ✅ OBTENER USUARIO
      User user;

      // Opción 1: Si el backend envía usuario en la respuesta
      if (jsonResponse.containsKey('usuario')) {
        user = User.fromJson(jsonResponse['usuario']);
      }
      // Opción 2: Crear desde token JWT
      else {
        user = _createUserFromToken(token, sanitizedInput);
      }

      // Guardar usuario en cache
      await _saveUserToPreferences(user);

      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      await _tokenManager.deleteToken();
      _client.updateToken(null);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
        ErrorMessages.operationFailed,
        technicalError: 'Error en logout: $e',
      );
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      // ✅ PRIMERO: Intentar obtener usuario del token JWT
      try {
        final userFromToken = _createUserFromToken(token, 'usuario');

        // Si el usuario es 'usuario_temp', es porque el token no tiene la info correcta
        if (userFromToken.username != 'usuario_temp' &&
            userFromToken.username != 'usuario') {
          return ApiResponse.success(userFromToken);
        }
      } catch (e) {
        '';
      }

      // ✅ SEGUNDO: Si el token no tiene info, buscar en otros lugares

      // Opción A: Verificar si hay información en SharedPreferences
      try {
        final user = await _getUserFromPreferences();
        if (user != null) {
          return ApiResponse.success(user);
        }
      } catch (e) {
        '';
      }

      // Opción B: Si el backend tiene endpoint para usuario actual

      // Lista de posibles endpoints
      final possibleEndpoints = [
        '/auth/me',
        '/auth/profile',
        '/usuario/actual',
        '/usuario/perfil',
        '/user/me',
      ];

      for (final endpoint in possibleEndpoints) {
        try {
          final response = await _client.get<Map<String, dynamic>>(
            endpoint,
            fromJson: (json) => json as Map<String, dynamic>,
          );

          if (response.hasError) {
            continue; // Intentar con el siguiente endpoint
          }

          if (response.data != null) {
            final jsonResponse = response.data!;

            final user = User.fromJson(jsonResponse);

            // Guardar en cache para futuras consultas
            await _saveUserToPreferences(user);

            return ApiResponse.success(user);
          }
        } catch (e) {
          '';
        }
      }

      // ✅ ÚLTIMA OPCIÓN: Usuario mínimo desde información disponible

      final minimalUser = User(
        id: 1,
        username: 'Usuario',
        email: 'usuario@ejemplo.com',
        password: '',
        roles: [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );

      return ApiResponse.success(minimalUser);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Método para guardar/obtener usuario de SharedPreferences
  Future<void> _saveUserToPreferences(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', json.encode(user.toJson()));
    } catch (e) {
      '';
    }
  }

  Future<User?> _getUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user');

      if (userJson != null) {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      }
    } catch (e) {
      '';
    }
    return null;
  }

  Future<ApiResponse<bool>> validateToken() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        return ApiResponse.error(ErrorMessages.unauthorized);
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
        ErrorMessages.operationFailed,
        technicalError: 'Error validando token: $e',
      );
    }
  }

  // Helper function
  int min(int a, int b) => a < b ? a : b;

  User _createUserFromToken(String token, String fallbackUsername) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Token JWT inválido');
      }

      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));

      return User(
        id: payload['id'] ?? 0,
        username:
            payload['nombreUsuario'] ?? payload['username'] ?? fallbackUsername,
        email: payload['email'] ?? '$fallbackUsername@temp.com',
        password: '',
        roles:
            (payload['roles'] as List<dynamic>?)?.map((role) {
              if (role is String) {
                final roleName = role.toLowerCase();
                return Rol(id: roleName == 'admin' ? 1 : 2, nombre: roleName);
              }
              return Rol(id: 2, nombre: 'consult');
            }).toList() ??
            [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return User(
        id: 1,
        username: fallbackUsername,
        email: '$fallbackUsername@temp.com',
        password: '',
        roles: [Rol(id: 2, nombre: 'consult')],
        createdAt: DateTime.now(),
      );
    }
  }
}
