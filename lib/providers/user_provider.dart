import 'package:flutter/material.dart';
import '../services/data/user_repository.dart';
import '../services/service_locator.dart';
import '../models/user.dart';
import '../models/rol.dart';
import '../models/create_usuario_dto.dart';
import '../utils/error_messages.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository = ServiceLocator().userRepository;

  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _loading = false;
  bool _syncing = false;
  String _error = '';
  bool _creatingUser = false;
  Rol _selectedRol = Rol.consult;
  String _searchQuery = '';

  // Getters
  List<User> get users => _users;
  List<User> get filteredUsers => _filteredUsers;
  bool get loading => _loading;
  bool get syncing => _syncing;
  String get error => _error;
  bool get creatingUser => _creatingUser;
  Rol get selectedRol => _selectedRol;
  String get searchQuery => _searchQuery;

  // Lista de roles disponibles
  List<Rol> get availableRoles => [Rol.admin, Rol.consult];

  // Setters
  void setSelectedRol(Rol rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterUsers();
    notifyListeners();
  }

  // Filtrar usuarios por búsqueda
  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _users.where((user) {
        return user.username.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Cargar usuarios (con soporte offline)
  Future<void> loadUsers({bool forceRefresh = false}) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.getUsers(
        forceRefresh: forceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;
      } else {
        _users = response.data ?? [];
        _filterUsers(); // Aplicar filtro actual
      }

      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
    }
  }

  // Buscar usuarios (con soporte offline)
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadUsers();
      return;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.searchUsers(query);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;
      } else {
        _users = response.data ?? [];
        _filteredUsers = List.from(_users);
      }

      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
    }
  }

  // Crear usuario (solo online)
  Future<bool> createUser({
    required String nombreUsuario,
    required String email,
    required String password,
    required Rol rol,
  }) async {
    _creatingUser = true;
    _error = '';
    notifyListeners();

    try {
      // Crear DTO
      final usuarioDto = CreateUsuarioDto(
        nombreUsuario: nombreUsuario,
        email: email,
        password: password,
        rolNombre: rol.nombre,
      );

      final response = await _userRepository.createUserOnline(usuarioDto);

      _creatingUser = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Agregar nuevo usuario a la lista
        if (response.data != null) {
          _users.add(response.data!);
          _filterUsers();
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _creatingUser = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar usuario (solo online)
  Future<bool> updateUser(User user) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userRepository.updateUserOnline(user);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar usuario en la lista
        if (response.data != null) {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = response.data!;
            _filterUsers();
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Obtener usuario por ID (con soporte offline)
  Future<User?> getUserById(int id) async {
    try {
      final response = await _userRepository.getUserByIdLocal(id);
      if (!response.hasError) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sincronizar usuarios con backend
  Future<bool> syncUsers() async {
    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _userRepository.syncUsers();

      _syncing = false;

      if (success) {
        // Recargar usuarios después de sincronizar
        await loadUsers();
      } else {
        _error = 'No se pudo sincronizar con el servidor';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Obtener estadísticas (con soporte offline)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return await _userRepository.getUserStats();
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

  // Obtener estadísticas locales
  Future<Map<String, dynamic>> getLocalStats() async {
    try {
      return await _userRepository.getLocalStats();
    } catch (e) {
      return {
        'totalUsers': 0,
        'lastSyncFormatted': 'Nunca',
        'hasSession': false,
      };
    }
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar
  Future<void> refreshUsers() async {
    await loadUsers(forceRefresh: true);
  }

  // Obtener estadísticas por rol
  Map<String, int> getRoleStats() {
    final stats = <String, int>{'admin': 0, 'consult': 0};

    for (final user in _users) {
      if (user.isAdmin) {
        stats['admin'] = stats['admin']! + 1;
      }
      if (user.isConsult) {
        stats['consult'] = stats['consult']! + 1;
      }
    }

    return stats;
  }

  // Verificar si hay datos locales
  bool get hasLocalData => _users.isNotEmpty;

  // Limpiar datos (para logout)
  void clearData() {
    _users.clear();
    _filteredUsers.clear();
    _searchQuery = '';
    _error = '';
    notifyListeners();
  }
}
