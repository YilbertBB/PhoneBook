import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/local.dart';
import '../models/local_lite.dart'; // NUEVO
import '../utils/error_messages.dart';
import '../services/data/local_repository.dart';

class LocalProvider with ChangeNotifier {
  final LocalRepository _localRepository = ServiceLocator().localRepository;

  List<Local> _locals = [];
  final List<LocalLite> _localLites = []; // NUEVO
  final List<LocalLite> _allLocalLites = [];
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
  List<Local> get locals => _locals;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalLocals => _locals.length;

  // NUEVOS GETTERS PARA PAGINACIÓN
  List<LocalLite> get localLites => _localLites;
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

  // Cargar locales (OFFLINE-FIRST con paginación)
  Future<void> loadLocals({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';

    // Reiniciar paginación en carga forzada
    if (forceRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _localLites.clear();
      _allLocalLites.clear();
    }

    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _localRepository.getLocals(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_localLites.isNotEmpty || _locals.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;

          // Cargar datos locales paginados
          await _loadLocalLocalsPaginated();
        }
      } else {
        _locals = response.data ?? [];

        _locals.sort(
  (a, b) => a.name.toLowerCase().compareTo(
    b.name.toLowerCase(),
  ),
);

        _hasLoaded = true;
        _isOffline = false;

        // Convertir a modelos lite para lista
        _localLites.clear();
        _localLites.addAll(_locals.map((local) => LocalLite.fromLocal(local)));
        // _allLocalLites
        //   ..clear()
        //   ..addAll(_localLites);

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline y cargarlos
      if (_localLites.isNotEmpty || _locals.isNotEmpty) {
        _isOffline = true;
        await _loadLocalLocalsPaginated();
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar locales locales paginados
  Future<void> _loadLocalLocalsPaginated() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final lites = await _localRepository.getLocalLocalsLitePaginated(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _lastSearchQuery,
      );

      if (_currentPage == 0) {
        _localLites.clear();
        if (_lastSearchQuery.isEmpty) {
          _allLocalLites.clear();
        }
      }

      _localLites.addAll(lites);
      if (_lastSearchQuery.isEmpty) {
        _allLocalLites.addAll(lites);
      }
      _hasMore = lites.length == _pageSize;
      _currentPage++;
    } catch (e) {
      debugPrint('Error cargando locales locales paginados: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // NUEVO: Cargar más datos (infinite scroll)
  Future<void> loadMoreLocals() async {
    if (_isLoadingMore || !_hasMore || _loading) return;

    await _loadLocalLocalsPaginated();
  }

  // NUEVO: Buscar locales con debounce
  Future<void> searchLocals(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    _lastSearchQuery = query.trim();
    _isSearching = normalizedQuery.isNotEmpty;

    // Reiniciar paginación para búsqueda
    _currentPage = 0;
    if (normalizedQuery.isEmpty) {
      // Si la búsqueda está vacía, volver a cargar todos
      clearSearch();
      return;
    }

    final localLiteSource = _allLocalLites.isNotEmpty
        ? _allLocalLites
        : _localLites;

    final localResults = _locals.isNotEmpty
        ? _locals
              .where((local) => _matchesLocalSearch(local, normalizedQuery))
              .map((local) => LocalLite.fromLocal(local))
              .toList()
        : localLiteSource
              .where((local) => _matchesLocalLiteSearch(local, normalizedQuery))
              .toList();

    if (_locals.isNotEmpty || localLiteSource.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(localResults);
      _hasMore = false;
      notifyListeners();
      return;
    }

    _hasMore = true;
    _localLites.clear();
    _loading = true;
    notifyListeners();

    try {
      final results = await _localRepository.searchLocalsLitePaginated(
        query: _lastSearchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _localLites.clear();
      _localLites.addAll(results);
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

  bool _matchesLocalSearch(Local local, String query) {
    return local.name.toLowerCase().contains(query) ||
        local.phone.toLowerCase().contains(query);
  }

  bool _matchesLocalLiteSearch(LocalLite local, String query) {
    return local.name.toLowerCase().contains(query) ||
        local.phone.toLowerCase().contains(query);
  }

  // NUEVO: Setup scroll controller para infinite scroll
  void setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        loadMoreLocals();
      }
    });
  }

  // NUEVO: Cleanup scroll controller
  void disposeScrollController() {
    _scrollController.dispose();
  }

  // Obtener local por ID (OFFLINE-FIRST)
  Future<Local?> getLocalById(int id) async {
    // Primero buscar en lista local
    try {
      return _locals.firstWhere((local) => local.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _localRepository.getLocalById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _locals.add(response.data!);
        // Agregar también a la lista lite
        _localLites.add(LocalLite.fromLocal(response.data!));
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Crear local (siempre intenta API primero)
  Future<bool> createLocal(String name, String phone) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final local = Local(id: 0, name: name, phone: phone);
      final response = await _localRepository.createLocal(local);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir el nuevo local
        await loadLocals(forceRefresh: true);
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

  // Actualizar local
  Future<bool> updateLocal(Local local) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _localRepository.updateLocal(local);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _locals.indexWhere((l) => l.id == local.id);
        if (index != -1) {
          _locals[index] = response.data!;
        }
        // Actualizar en la lista lite si existe
        final liteIndex = _localLites.indexWhere((l) => l.id == local.id);
        if (liteIndex != -1) {
          _localLites[liteIndex] = LocalLite.fromLocal(response.data!);
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

  // Eliminar local
  Future<bool> deleteLocal(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _localRepository.deleteLocal(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _locals.removeWhere((local) => local.id == id);
        // Remover de la lista lite
        _localLites.removeWhere((local) => local.id == id);
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

  // Buscar locales (método existente mantenido para compatibilidad)
  Future<List<Local>> searchLocalsOld(String query) async {
    try {
      final response = await _localRepository.searchLocals(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _locals.where((local) {
        return local.name.toLowerCase().contains(query.toLowerCase()) ||
            local.phone.contains(query);
      }).toList();
    } catch (e) {
      return _locals.where((local) {
        return local.name.toLowerCase().contains(query.toLowerCase()) ||
            local.phone.contains(query);
      }).toList();
    }
  }

  // NUEVO: Actualizar estadísticas locales
  Future<void> _updateLocalStats() async {
    try {
      final stats = await _localRepository.getLocalStats();
      _localDataCount = stats['totalLocals'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      ''; // Silenciar error
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncLocals() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _localRepository.syncLocals();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadLocals(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar locales';
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
  Future<void> refreshLocals() async {
    await loadLocals(forceRefresh: true);
  }

  void clearSearch() {
    _lastSearchQuery = '';
    _isSearching = false;
    _currentPage = 0;
    _hasMore = _localLites.length > _pageSize;

    if (_locals.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(_locals.map((local) => LocalLite.fromLocal(local)));
      _allLocalLites
        ..clear()
        ..addAll(_localLites);
      _hasMore = false;
    } else if (_allLocalLites.isNotEmpty) {
      _localLites
        ..clear()
        ..addAll(_allLocalLites);
      _hasMore = false;
    }

    notifyListeners();
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadLocals();
    }

    // Setup scroll controller
    setupScrollController();

    // Actualizar estadísticas
    await _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _locals.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'hasPhone': _locals.where((l) => l.phone.isNotEmpty).length,
    };
  }

  @override
  void dispose() {
    disposeScrollController();
    super.dispose();
  }
}
