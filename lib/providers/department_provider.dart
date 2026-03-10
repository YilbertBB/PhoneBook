import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/department.dart';
import '../models/department_lite.dart';
import '../utils/error_messages.dart';
import '../services/data/department_repository.dart';

class DepartmentProvider with ChangeNotifier {
  final DepartmentRepository _departmentRepository =
      ServiceLocator().departmentRepository;

  List<Department> _departments = [];
  final List<DepartmentLite> _departmentLites = [];
  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';

  // NUEVO: Propiedades para paginación
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasMore = true; // NUEVO: Esta propiedad falta
  bool _isLoadingMore = false; // NUEVO
  bool _isSearching = false; // NUEVO
  String _lastSearchQuery = ''; // NUEVO
  final int _pageSize = 20; // NUEVO

  // Propiedades offline existentes
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // Getters existentes
  List<Department> get departments => _departments;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalDepartments => _departments.length;

  // NUEVOS GETTERS PARA PAGINACIÓN
  List<DepartmentLite> get departmentLites => _departmentLites;
  ScrollController get scrollController => _scrollController;
  bool get hasMore => _hasMore; // NUEVO: Agregar este getter
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;

  // Getters offline existentes
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // Cargar departamentos (OFFLINE-FIRST con paginación)
  Future<void> loadDepartments({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';

    // Reiniciar paginación en carga forzada
    if (forceRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _departmentLites.clear();
    }

    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _departmentRepository.getDepartments(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_departmentLites.isNotEmpty || _departments.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;

          // Cargar datos locales paginados
          await _loadLocalDepartmentsPaginated();
        }
      } else {
        _departments = response.data ?? [];
        _hasLoaded = true;
        _isOffline = false;

        // Convertir a modelos lite para lista
        _departmentLites.clear();
        _departmentLites.addAll(
          _departments.map((dept) => DepartmentLite.fromDepartment(dept)),
        );

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline y cargarlos
      if (_departmentLites.isNotEmpty || _departments.isNotEmpty) {
        _isOffline = true;
        await _loadLocalDepartmentsPaginated();
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar departamentos locales paginados
  Future<void> _loadLocalDepartmentsPaginated() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final lites = await _departmentRepository
          .getLocalDepartmentsLitePaginated(
            page: _currentPage,
            pageSize: _pageSize,
            searchQuery: _lastSearchQuery,
          );

      if (_currentPage == 0) {
        _departmentLites.clear();
      }

      _departmentLites.addAll(lites);
      _hasMore = lites.length == _pageSize;
      _currentPage++;
    } catch (e) {
      debugPrint('Error cargando departamentos locales paginados: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // NUEVO: Cargar más datos (infinite scroll)
  Future<void> loadMoreDepartments() async {
    if (_isLoadingMore || !_hasMore || _loading) return;

    await _loadLocalDepartmentsPaginated();
  }

  // NUEVO: Buscar departamentos con debounce
  Future<void> searchDepartments(String query) async {
    _lastSearchQuery = query;
    _isSearching = query.isNotEmpty;

    // Reiniciar paginación para búsqueda
    _currentPage = 0;
    _hasMore = true;
    _departmentLites.clear();

    if (query.isEmpty) {
      // Si la búsqueda está vacía, volver a cargar todos
      await loadDepartments(forceRefresh: false);
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final results = await _departmentRepository
          .searchDepartmentsLitePaginated(
            query: query,
            page: _currentPage,
            pageSize: _pageSize,
          );

      _departmentLites.clear();
      _departmentLites.addAll(results);
      _hasMore = results.length == _pageSize;
      _currentPage++;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Error en búsqueda: $e';
      notifyListeners();
    }
  }

  // NUEVO: Setup scroll controller para infinite scroll
  void setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        loadMoreDepartments();
      }
    });
  }

  // NUEVO: Cleanup scroll controller
  void disposeScrollController() {
    _scrollController.dispose();
  }

  // Obtener departamento por ID (OFFLINE-FIRST)
  Future<Department?> getDepartmentById(int id) async {
    // Primero buscar en lista local
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _departmentRepository.getDepartmentById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _departments.add(response.data!);
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Crear departamento (siempre intenta API primero)
  Future<bool> createDepartment(String name, String phone) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final department = Department(id: 0, name: name, phone: phone);
      final response = await _departmentRepository.createDepartment(department);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir el nuevo departamento
        await loadDepartments(forceRefresh: true);
        _isOffline = false;
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar departamento
  Future<bool> updateDepartment(Department department) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _departmentRepository.updateDepartment(department);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _departments.indexWhere((d) => d.id == department.id);
        if (index != -1) {
          _departments[index] = response.data!;
        }
        // Actualizar en la lista lite si existe
        final liteIndex = _departmentLites.indexWhere(
          (d) => d.id == department.id,
        );
        if (liteIndex != -1) {
          _departmentLites[liteIndex] = DepartmentLite.fromDepartment(
            response.data!,
          );
        }
        _isOffline = false;
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

  // Eliminar departamento
  Future<bool> deleteDepartment(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _departmentRepository.deleteDepartment(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _departments.removeWhere((dept) => dept.id == id);
        // Remover de la lista lite
        _departmentLites.removeWhere((dept) => dept.id == id);
        _isOffline = false;
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

  // Buscar departamentos (método existente mantenido para compatibilidad)
  Future<List<Department>> searchDepartmentsOld(String query) async {
    try {
      final response = await _departmentRepository.searchDepartments(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _departments.where((dept) {
        return dept.name.toLowerCase().contains(query.toLowerCase()) ||
            dept.phone.contains(query);
      }).toList();
    } catch (e) {
      return _departments.where((dept) {
        return dept.name.toLowerCase().contains(query.toLowerCase()) ||
            dept.phone.contains(query);
      }).toList();
    }
  }

  // NUEVO: Actualizar estadísticas locales
  Future<void> _updateLocalStats() async {
    try {
      final stats = await _departmentRepository.getLocalStats();
      _localDataCount = stats['totalDepartments'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      debugPrint(
        'Error actualizando estadísticas locales de departamentos: $e',
      );
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncDepartments() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _departmentRepository.syncDepartments();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadDepartments(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar departamentos';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refreshDepartments() async {
    await loadDepartments(forceRefresh: true);
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadDepartments();
    }

    // Setup scroll controller
    setupScrollController();

    // Actualizar estadísticas
    await _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _departments.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'hasPhone': _departments.where((d) => d.phone.isNotEmpty).length,
    };
  }

  @override
  void dispose() {
    disposeScrollController();
    super.dispose();
  }
}
