import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rol.dart';
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth_security_service.dart';
import '../services/service_locator.dart';
import '../utils/validators.dart';
import '../utils/error_messages.dart';

class AuthProvider extends ChangeNotifier {
  // Servicios
  final AuthService _authService = ServiceLocator().authService;
  final AuthSecurityService _securityService =
      ServiceLocator().authSecurityService;

  // Estados principales
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;
  User? _user;

  // Estados para compatibilidad
  bool _loading = false;
  String? _error;
  bool _checkingAuth = true;
  bool _hasCheckedAuth = false;
  String? _token;

  // ✅ CONTROLES PARA EVITAR BUCLES Y NOTIFICACIONES INNECESARIAS
  bool _isCheckingAuthStatus = false;
  DateTime? _lastAuthCheck;
  static const Duration _authCheckCooldown = Duration(seconds: 30);

  // ✅ CONTROL DE NOTIFICACIONES
  User? _previousUser;
  bool _previousAuthState = false;
  bool _previousLoadingState = true;

  // Getters principales
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  // Getters para compatibilidad
  bool get loading => _loading;
  String? get error => _error;
  bool get isCheckingAuth => _checkingAuth;
  bool get hasCheckedAuth => _hasCheckedAuth;
  String? get token => _token;

  // Constructor optimizado
  AuthProvider() {
    _initializeDelayed();
  }

  void _initializeDelayed() {
    // Pequeño delay para evitar conflictos con inicialización de servicios
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_hasCheckedAuth && !_isCheckingAuthStatus) {
        _performAuthCheck();
      }
    });
  }

  // ✅ MÉTODO PÚBLICO para verificar estado (con cooldown)
  Future<void> checkAuthStatus({bool force = false}) async {
    // Si ya se está verificando, salir
    if (_isCheckingAuthStatus) {
      return;
    }

    // Verificar cooldown (a menos que force=true)
    if (!force &&
        _lastAuthCheck != null &&
        DateTime.now().difference(_lastAuthCheck!) < _authCheckCooldown) {
      return;
    }

    await _performAuthCheck();
  }

  // ✅ MÉTODO PRIVADO para la verificación real
  Future<void> _performAuthCheck() async {
    _isCheckingAuthStatus = true;
    _lastAuthCheck = DateTime.now();

    if (!_isLoading) {
      _isLoading = true;
      _loading = true;
      _checkingAuth = true;
      _safeNotifyListeners(); // Notificar cambio de estado loading
    }

    try {
      // Obtener token del gestor seguro
      _token = await ServiceLocator().secureTokenManager.getToken();

      if (_token != null && _token!.isNotEmpty) {
        try {
          // Intentar obtener usuario del servicio (con timeout)
          final userResponse = await _authService.getCurrentUser().timeout(
            const Duration(seconds: 10),
          );

          if (!userResponse.hasError && userResponse.data != null) {
            _user = userResponse.data;
            _isAuthenticated = true;
            _errorMessage = null;
            _error = null;
          } else {
            _handleInvalidToken(userResponse);
          }
        } catch (e) {
          // En caso de error de conexión, mantener estado actual
          // No limpiar el token porque puede ser solo un problema temporal
        }
      } else {
        _user = null;
        _isAuthenticated = false;
        _errorMessage = null;
        _error = null;
      }
    } catch (e) {
      _errorMessage = 'Error verificando sesión';
      _error = e.toString();
    } finally {
      _isLoading = false;
      _loading = false;
      _checkingAuth = false;
      _hasCheckedAuth = true;
      _isCheckingAuthStatus = false;
      _safeNotifyListeners(); // Notificar cambio de estado final
    }
  }

  void _handleInvalidToken(dynamic response) {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = response.error;
    _error = response.error;

    // Solo limpiar token si es específicamente un error 401
    if (response.statusCode == 401) {
      ServiceLocator().secureTokenManager.deleteToken().then((_) {
        _token = null;
      });
    }
  }

  // ✅ LOGIN REAL con backend usando AuthService
  Future<bool> login(
    String usernameOrEmail,
    String password, {
    bool forceRefresh = false,
  }) async {
    // Validaciones iniciales
    final usernameError = _validateUsernameOrEmail(usernameOrEmail);
    final passwordError = Validators.validatePassword(password);

    if (usernameError != null || passwordError != null) {
      _errorMessage = usernameError ?? passwordError!;
      _error = usernameError ?? passwordError!;
      _safeNotifyListeners();
      return false;
    }

    // Verificar rate limiting
    if (!await _securityService.canAttemptLogin()) {
      final lockoutTime = await _securityService.getLockoutTime();
      final remainingTime = lockoutTime?.difference(DateTime.now());

      if (remainingTime != null) {
        final minutes = remainingTime.inMinutes;
        final seconds = remainingTime.inSeconds % 60;
        _errorMessage =
            '⚠️ Demasiados intentos fallidos. Espere $minutes:${seconds.toString().padLeft(2, '0')} minutos.';
        _error = _errorMessage;
      } else {
        _errorMessage = '⚠️ Demasiados intentos fallidos. Espere 15 minutos.';
        _error = _errorMessage;
      }

      _safeNotifyListeners();
      return false;
    }

    // Verificar conexión a internet
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasConnection) {
        _errorMessage = ErrorMessages.noInternet;
        _error = _errorMessage;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando conectividad: $e');
    }

    _isLoading = true;
    _loading = true;
    _errorMessage = null;
    _error = null;
    _safeNotifyListeners();

    try {
      final response = await _authService
          .login(usernameOrEmail, password)
          .timeout(const Duration(seconds: 15));

      if (response.hasError) {
        _errorMessage = response.error ?? ErrorMessages.invalidCredentials;
        _error = _errorMessage;

        await _securityService.recordFailedAttempt();
        final remainingAttempts = await _securityService.getRemainingAttempts();

        if (remainingAttempts > 0) {
          _errorMessage =
              '${_errorMessage ?? ""}\n🔄 Intentos: $remainingAttempts';
        } else {
          _errorMessage = '${_errorMessage ?? ""}\n🔒 Cuenta bloqueada';
        }

        _isLoading = false;
        _loading = false;
        _safeNotifyListeners();
        return false;
      } else {
        _user = response.data;
        _isAuthenticated = true;
        _hasCheckedAuth = true;

        _token = await ServiceLocator().secureTokenManager.getToken();

        await _securityService.resetAttempts();

        final prefs = await SharedPreferences.getInstance();
        if (_user != null) {
          await prefs.setString('user_email', _user!.email);
          await prefs.setString('user_name', _user!.username);
        }

        // ✅ RESETEAR EL COOLDOWN después de login exitoso
        _lastAuthCheck = DateTime.now();

        _isLoading = false;
        _loading = false;
        _safeNotifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _loading = false;
      _errorMessage = ErrorMessages.fromException(e);
      _error = _errorMessage;

      if (!_errorMessage!.contains('conexión') &&
          !_errorMessage!.contains('internet')) {
        await _securityService.recordFailedAttempt();
      }

      _safeNotifyListeners();
      return false;
    }
  }

  // ✅ Método para refrescar token
  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refreshAccessToken();

      if (response.hasError) {
        return false;
      }

      // Actualizar token
      _token = await ServiceLocator().secureTokenManager.getToken();

      // Actualizar usuario si es necesario
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.hasError && userResponse.data != null) {
        _user = userResponse.data;
        _safeNotifyListeners();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Logout optimizado
  Future<void> logout() async {
    _isLoading = true;
    _loading = true;
    _safeNotifyListeners();

    try {
      // Logout en el backend
      await _authService.logout();

      // Limpiar datos locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      _user = null;
      _token = null;
      _isAuthenticated = false;
      _hasCheckedAuth = true;
      _errorMessage = null;
      _error = null;
    } catch (e) {
      _errorMessage = ErrorMessages.fromException(e);
      _error = _errorMessage;
      // Aún así limpiar estado local
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _hasCheckedAuth = true;
    } finally {
      _isLoading = false;
      _loading = false;
      _safeNotifyListeners();
    }
  }

  // ============================
  // MÉTODOS QUE NECESITA EL LOGINSCREEN
  // ============================

  // ✅ Método para verificar token localmente
  bool isTokenValidLocally(String token) {
    return token.isNotEmpty && token != 'null';
  }

  // ✅ Método para obtener usuario caché (de SharedPreferences)
  User? getCachedUser() {
    return _user;
  }

  // ✅ Método para restaurar sesión cacheada
  Future<bool> restoreCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');

      if (storedToken != null && storedToken.isNotEmpty && email != null) {
        // Verificar token localmente
        if (isTokenValidLocally(storedToken)) {
          _token = storedToken;
          _user = User(
            id: 1,
            username: name ?? email.split('@').first,
            email: email,
            password: '',
            roles: [Rol(id: 1, nombre: 'admin')],
            createdAt: DateTime.now(),
          );
          _isAuthenticated = true;
          _errorMessage = null;
          _error = null;

          _safeNotifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================
  // MÉTODOS DE VALIDACIÓN
  // ============================

  String? _validateUsernameOrEmail(String? value) {
    return Validators.validateUsernameOrEmail(value);
  }

  void clearError() {
    if (_errorMessage != null || _error != null) {
      _errorMessage = null;
      _error = null;
      _safeNotifyListeners();
    }
  }

  // ✅ NOTIFICADOR INTELIGENTE (EVITA NOTIFICACIONES INNECESARIAS)
  void _safeNotifyListeners() {
    // ✅ Solo notificar si realmente cambió algo importante
    final userChanged = _user?.id != _previousUser?.id;
    final authChanged = _isAuthenticated != _previousAuthState;
    final loadingChanged = _isLoading != _previousLoadingState;

    if (userChanged || authChanged || loadingChanged) {
      _previousUser = _user;
      _previousAuthState = _isAuthenticated;
      _previousLoadingState = _isLoading;

      Future.microtask(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  // ============================
  // MÉTODOS PARA COMPATIBILIDAD
  // ============================

  User get guestUser {
    return User(
      id: 0,
      username: 'Invitado',
      email: 'invitado@ejemplo.com',
      password: '',
      roles: [Rol(id: 2, nombre: 'consult')],
      createdAt: DateTime.now(),
    );
  }

  bool get isAdmin =>
      _user?.roles.any((role) => role.nombre == 'admin') ?? false;

  List<String> get userRoles =>
      _user?.roles.map((r) => r.nombre).toList() ?? [];

  bool hasRole(String roleName) {
    return _user?.roles.any((role) => role.nombre == roleName) ?? false;
  }

  bool hasAnyRole(List<String> roleNames) {
    return _user?.roles.any((role) => roleNames.contains(role.nombre)) ?? false;
  }

  String get displayName {
    if (_user == null) return 'Invitado';
    return _user!.username.isNotEmpty ? _user!.username : _user!.email;
  }

  String get displayEmail {
    if (_user == null) return '';
    return _user!.email;
  }

  bool get isGuest => _user == null;

  // Obtener información de seguridad
  Future<Map<String, dynamic>> getSecurityInfo() async {
    final attempts = await _securityService.getFailedAttempts();
    final remaining = await _securityService.getRemainingAttempts();
    final isLocked = await _securityService.isLockedOut();
    final lockoutTime = await _securityService.getLockoutTime();

    return {
      'failedAttempts': attempts,
      'remainingAttempts': remaining,
      'isLockedOut': isLocked,
      'lockoutTime': lockoutTime,
      'maxAttempts': 5,
    };
  }

  // Helper methods
  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      _isLoading = value;
      _safeNotifyListeners();
    }
  }

  // ============================
  // MÉTODOS DE GESTIÓN DE CACHÉ (OPCIONAL - Mantener si los usas)
  // ============================

  // Future<void> _clearStoredData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('auth_token');
  //   await prefs.remove('user_email');
  //   await prefs.remove('user_name');
  // }

  // Método de registro (si lo necesitas)
  Future<bool> register(String email, String password, String name) async {
    // Esto sería una implementación futura
    return false;
  }

  // ============================
  // MÉTODOS DE GESTIÓN DE CACHÉ (Solo si realmente los necesitas)
  // ============================

  // Método para obtener información detallada del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final supportDir = await getApplicationSupportDirectory();

      int totalSize = 0;
      int itemCount = 0;
      Map<String, int> allDetails = {};
      Map<String, int> categories = {};

      // Directorios a escanear
      final directories = {
        'Documents': appDir,
        'Cache': tempDir,
        'Support': supportDir,
      };

      for (var entry in directories.entries) {
        final dirName = entry.key;
        final directory = entry.value;
        int dirSize = 0;
        int dirItems = 0;

        if (await directory.exists()) {
          final files = await directory.list(recursive: true).toList();

          for (var file in files) {
            if (file is File) {
              try {
                final stat = await file.stat();
                dirSize += stat.size;
                dirItems++;

                final relativePath = path.relative(
                  file.path,
                  from: directory.path,
                );
                allDetails['$dirName/$relativePath'] = stat.size;
              } catch (e) {
                debugPrint('Error accediendo a ${file.path}: $e');
              }
            }
          }

          categories[dirName] = dirSize;
          totalSize += dirSize;
          itemCount += dirItems;
        }
      }

      // Verificar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int prefsSize = 0;

      for (String key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          final size = value.toString().length * 2;
          prefsSize += size;
          allDetails['SharedPrefs/$key'] = size;
        }
      }

      categories['SharedPrefs'] = prefsSize;
      totalSize += prefsSize;
      itemCount += keys.length;

      // Verificar base de datos
      final dbFile = File(path.join(appDir.path, 'app_database.db'));
      int dbSize = 0;
      if (await dbFile.exists()) {
        try {
          final stat = await dbFile.stat();
          dbSize = stat.size;
          allDetails['Database/app_database.db'] = dbSize;
        } catch (e) {
          debugPrint('Error accediendo a base de datos: $e');
        }
      }

      categories['Database'] = dbSize;
      totalSize += dbSize;
      if (dbSize > 0) itemCount++;

      return {
        'total': totalSize,
        'items': itemCount,
        'details': allDetails,
        'categories': categories,
        'directories': directories.keys.toList(),
      };
    } catch (e) {
      return {
        'total': 0,
        'items': 0,
        'details': <String, int>{},
        'categories': {},
        'directories': [],
      };
    }
  }

  // Borrar caché de la aplicación
  Future<bool> clearAppCache() async {
    try {
      // 1. Limpiar directorio cache
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(appDir.path, 'cache'));

      if (await cacheDir.exists()) {
        try {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        } catch (e) {
          debugPrint('Error limpiando directorio cache: $e');
        }
      }

      // 2. Limpiar datos de autenticación
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      // 3. Limpiar estado (pero mantener la app funcional)
      _user = null;
      _token = null;
      _isAuthenticated = false;

      _safeNotifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Borrar TODOS los datos de la aplicación (más agresivo)
  Future<bool> clearAllData() async {
    try {
      // 1. Limpiar todos los directorios
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final supportDir = await getApplicationSupportDirectory();

      final directories = [appDir, tempDir, supportDir];

      for (var directory in directories) {
        if (await directory.exists()) {
          try {
            await directory.delete(recursive: true);
            // Recrear el directorio vacío
            await directory.create(recursive: true);
          } catch (e) {
            debugPrint('✗ Error limpiando ${directory.path}: $e');
          }
        }
      }

      // 2. Eliminar base de datos
      final dbFile = File(path.join(appDir.path, 'app_database.db'));
      if (await dbFile.exists()) {
        try {
          await dbFile.delete();
        } catch (e) {
          debugPrint('✗ Error eliminando base de datos: $e');
        }
      }

      // 3. Borrar TODOS los datos de SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        debugPrint('✗ Error limpiando SharedPreferences: $e');
      }

      // 4. Limpiar caché de imágenes (si usas cached_network_image)
      try {
        final cacheDir = Directory(
          path.join(tempDir.path, 'libCachedImageData'),
        );
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('✗ Error limpiando caché de imágenes: $e');
      }

      // 5. Limpiar estado de la aplicación
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _error = null;

      _safeNotifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
