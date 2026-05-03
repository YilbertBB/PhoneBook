import 'package:flutter/material.dart';
import '../services/data/worker_repository.dart';
import '../services/service_locator.dart';
import '../models/worker.dart';
import '../models/worker_lite.dart';
import '../utils/error_messages.dart';

class WorkerProvider with ChangeNotifier {
  final WorkerRepository _workerRepository = ServiceLocator().workerRepository;

  // DATOS PAGINADOS
  List<Worker> _allWorkers = [];
  List<WorkerLite> _allWorkersLite = []; // Versión ligera para listas
  List<WorkerLite> _filteredWorkersLite = [];

  // ESTADO DE PAGINACIÓN
  int _currentPage = 0;
  final int _pageSize = 30; // Cantidad por página
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // ESTADO GENERAL
  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';
  String _searchQuery = '';

  // OFFLINE
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // GETTERS
  List<Worker> get workers => _allWorkers;

  // Para UI - usa WorkerLite cuando sea posible
  List<WorkerLite> get workersLite =>
      _filteredWorkersLite.isEmpty && _searchQuery.isEmpty
      ? _allWorkersLite
      : _filteredWorkersLite;

  List<WorkerLite> get allWorkersLite => _allWorkersLite;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalWorkers => _allWorkers.length;
  int get filteredCount => _filteredWorkersLite.length;

  // PAGINACIÓN
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get pageSize => _pageSize;
  int get loadedCount => _allWorkersLite.length;

  // OFFLINE
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // ============ MÉTODOS PRINCIPALES (PAGINACIÓN) ============

  // Cargar primera página
  Future<void> loadWorkers({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      // Cargar todos los trabajadores de una vez (sin paginación backend)
      final response = await _workerRepository.getWorkers(
        forceRefresh: forceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_allWorkers.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;
        }
      } else {
        _allWorkers = response.data ?? [];

        // Convertir a WorkerLite para listas
        _allWorkersLite = _allWorkers
            .map((w) => WorkerLite.fromWorker(w))
            .toList();

        _hasLoaded = true;
        _isOffline = false;
        _applySearchFilter();

        // Actualizar estadísticas locales
        await _updateLocalStats();

        // Calcular si hay más datos (para paginación cliente)
        _hasMore = _allWorkersLite.length > _pageSize;
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline
      if (_allWorkers.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // Cargar más datos (paginación del lado cliente)
  Future<bool> loadMoreWorkers() async {
    if (_isLoadingMore || !_hasMore || _allWorkersLite.isEmpty) {
      return false;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Simular delay para paginación (opcional)
      await Future.delayed(const Duration(milliseconds: 300));

      _currentPage++;

      // En paginación cliente, ya tenemos todos los datos
      // Simplemente actualizamos el estado
      final totalItems = _allWorkersLite.length;
      final loadedItems = (_currentPage + 1) * _pageSize;

      _hasMore = loadedItems < totalItems;

      _isLoadingMore = false;

      // Aplicar filtro de búsqueda si existe
      if (_searchQuery.isNotEmpty) {
        _applySearchFilter();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isLoadingMore = false;
      _hasMore = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener trabajadores visibles actualmente (paginados)
  List<WorkerLite> get visibleWorkers {
    if (_allWorkersLite.isEmpty) return [];

    // final startIndex = 0;
    final endIndex = _hasMore
        ? (_currentPage + 1) * _pageSize
        : _allWorkersLite.length;

    final workersToShow = _filteredWorkersLite.isEmpty && _searchQuery.isEmpty
        ? _allWorkersLite
        : _filteredWorkersLite;

    // Limitar a lo que cabe en la página actual
    return workersToShow.sublist(
      0,
      endIndex > workersToShow.length ? workersToShow.length : endIndex,
    );
  }

  // Buscar trabajadores (optimizada para paginación)
  void searchWorkers(String query) {
    _searchQuery = query;
    _currentPage = 0; // Resetear a primera página al buscar
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredWorkersLite = _allWorkersLite;
      _hasMore = _allWorkersLite.length > _pageSize;
    } else {
      final query = _searchQuery.toLowerCase();
      final filtered = _allWorkersLite.where((worker) {
        final fullName = worker.fullName.toLowerCase();
        final carnet = worker.carnetID.toLowerCase();
        final phone = worker.phone.toLowerCase();

        return fullName.contains(query) ||
            carnet.contains(query) ||
            phone.contains(query);
      }).toList();

      _filteredWorkersLite = filtered;
      _hasMore = filtered.length > _pageSize;
    }
  }

  // Obtener trabajador completo por ID
  Future<Worker?> getWorkerById(int id) async {
    // Buscar en lista local
    try {
      return _allWorkers.firstWhere((worker) => worker.id == id);
    } catch (e) {
      // Si no está local, intentar cargar individualmente
      final response = await _workerRepository.getWorkerById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local si se encontró
        _allWorkers.add(response.data!);
        _allWorkersLite.add(WorkerLite.fromWorker(response.data!));
        _applySearchFilter();
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }

  // Obtener WorkerLite por ID (más rápido para listas)
  WorkerLite? getWorkerLiteById(int id) {
    try {
      return _allWorkersLite.firstWhere((worker) => worker.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============ MÉTODOS DE OFFLINE (MANTENER) ============

  Future<void> _updateLocalStats() async {
    try {
      final stats = await _workerRepository.getLocalStats();
      _localDataCount = stats['totalWorkers'] as int;

      if (stats['lastSyncDate'] != null) {
        _lastSyncDate = DateTime.parse(stats['lastSyncFormatted']);
      }
    } catch (e) {
      debugPrint('Error actualizando estadísticas locales: $e');
    }
  }

  Future<bool> syncWorkers() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _workerRepository.syncWorkers();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadWorkers(forceRefresh: true);
        _isOffline = false;
        _showSuccessMessage('✅ Datos sincronizados correctamente');
      } else {
        _error = 'Error al sincronizar datos';
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

  // ============ CRUD OPERATIONS ============

  Future<bool> createWorker(Worker worker) async {
    debugPrint('[WorkerProvider][CREATE] Requested: ${_workerLog(worker)}');

    if (_loading) {
      debugPrint('[WorkerProvider][CREATE] Ignored because provider is loading');
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();
    debugPrint('[WorkerProvider][CREATE] Calling repository');

    try {
      final response = await _workerRepository.createWorker(worker);
      _loading = false;
      debugPrint(
        '[WorkerProvider][CREATE] Repository response hasError=${response.hasError} status=${response.statusCode} error="${response.error}" technical="${response.technicalError}" data=${response.data != null ? _workerLog(response.data!) : null}',
      );

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        debugPrint('[WorkerProvider][CREATE] Failed: $_error');
        notifyListeners();
        return false;
      } else {
        _allWorkers.add(response.data!);
        _allWorkersLite.add(WorkerLite.fromWorker(response.data!));
        _applySearchFilter();
        _isOffline = false;
        debugPrint(
          '[WorkerProvider][CREATE] Success. totalWorkers=${_allWorkers.length} visible=${visibleWorkers.length}',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      debugPrint('[WorkerProvider][CREATE] Exception: $e parsedError=$_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorker(Worker worker) async {
    debugPrint('[WorkerProvider][EDIT] Requested: ${_workerLog(worker)}');

    if (_loading) {
      debugPrint('[WorkerProvider][EDIT] Ignored because provider is loading');
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();
    debugPrint('[WorkerProvider][EDIT] Calling repository');

    try {
      final response = await _workerRepository.updateWorker(worker);
      _loading = false;
      debugPrint(
        '[WorkerProvider][EDIT] Repository response hasError=${response.hasError} status=${response.statusCode} error="${response.error}" technical="${response.technicalError}" data=${response.data != null ? _workerLog(response.data!) : null}',
      );

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        debugPrint('[WorkerProvider][EDIT] Failed: $_error');
        notifyListeners();
        return false;
      } else {
        final index = _allWorkers.indexWhere((w) => w.id == worker.id);
        if (index != -1) {
          _allWorkers[index] = response.data!;
          _allWorkersLite[index] = WorkerLite.fromWorker(response.data!);
          _applySearchFilter();
          debugPrint('[WorkerProvider][EDIT] Updated local index=$index');
        } else {
          debugPrint(
            '[WorkerProvider][EDIT] Warning: worker id=${worker.id} was not found in local list',
          );
        }
        _isOffline = false;
        debugPrint(
          '[WorkerProvider][EDIT] Success. totalWorkers=${_allWorkers.length} visible=${visibleWorkers.length}',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      debugPrint('[WorkerProvider][EDIT] Exception: $e parsedError=$_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorker(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _workerRepository.deleteWorker(id);
      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        _allWorkers.removeWhere((w) => w.id == id);
        _allWorkersLite.removeWhere((w) => w.id == id);
        _applySearchFilter();
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

  // ============ UTILIDADES ============

  void clearSearch() {
    _searchQuery = '';
    _filteredWorkersLite = _allWorkersLite;
    _currentPage = 0;
    _hasMore = _allWorkersLite.length > _pageSize;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshWorkers() async {
    await loadWorkers(forceRefresh: true);
  }

  // Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadWorkers();
    }
    await _updateLocalStats();
  }

  // Resetear paginación
  void resetPagination() {
    _currentPage = 0;
    _hasMore = _allWorkersLite.length > _pageSize;
    notifyListeners();
  }

  // Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    final withDepartment = _allWorkers.where((w) => w.hasDepartment).length;
    final withLocal = _allWorkers.where((w) => w.hasLocal).length;
    final withPhone = _allWorkers.where((w) => w.hasPhone).length;
    final birthdayThisMonth = _allWorkers
        .where((w) => w.hasBirthdayThisMonth)
        .length;
    final birthdayToday = _allWorkers.where((w) => w.hasBirthdayToday).length;

    return {
      'total': _allWorkers.length,
      'loaded': _allWorkersLite.length,
      'visible': visibleWorkers.length,
      'withDepartment': withDepartment,
      'withLocal': withLocal,
      'withPhone': withPhone,
      'birthdayThisMonth': birthdayThisMonth,
      'birthdayToday': birthdayToday,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'currentPage': _currentPage,
      'hasMore': _hasMore,
    };
  }

  void _showSuccessMessage(String message) {
    debugPrint('Success: $message');
  }

  String _workerLog(Worker worker) {
    return {
      'id': worker.id,
      'nombre': worker.name,
      'apellido': worker.lastName,
      'carnetIdentidad': worker.carnetID,
      'numeroCelular': worker.phone,
      'direccion': worker.address,
      'fechaCumpleanno': worker.fechaCumpleannos,
      'departamentoId': worker.departamentoID,
      'localId': worker.localId,
    }.toString();
  }

  // Obtener trabajadores por departamento (paginados)
  List<WorkerLite> getWorkersByDepartmentLite(int departmentId) {
    final filtered = _allWorkersLite
        .where((worker) => worker.departamentoID == departmentId)
        .toList();

    // Aplicar paginación
    // final startIndex = 0;
    final endIndex = (_currentPage + 1) * _pageSize;
    return endIndex > filtered.length
        ? filtered
        : filtered.sublist(0, endIndex);
  }

  // Obtener trabajadores por local (paginados)
  List<WorkerLite> getWorkersByLocalLite(int localId) {
    final filtered = _allWorkersLite
        .where((worker) => worker.localId == localId)
        .toList();

    // final startIndex = 0;
    final endIndex = (_currentPage + 1) * _pageSize;
    return endIndex > filtered.length
        ? filtered
        : filtered.sublist(0, endIndex);
  }
}
